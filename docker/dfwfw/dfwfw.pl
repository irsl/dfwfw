#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Data::Dumper;
use FindBin qw($Bin);
use JSON::XS;
use File::Slurp;
use constant IPTABLES_TMP_FILE => "/tmp/dfwfw";
use constant DFWFW_CONFIG => "/etc/dfwfw.conf";
use constant IPTABLES_TABLES => ["filter","raw","nat","mangle","security"];
use Getopt::Long;
use experimental 'smartmatch';

BEGIN {
 push @INC, "$Bin";
}
use WebService::Docker;

local $| = 1;


my ($c_dry_run, $c_one_shot) = (0, 0);

  GetOptions ("dry-run" => \$c_dry_run,
              "one-shot"   => \$c_one_shot)
  or die("Usage: $0 [--dry-run] [--one-shot]");


my %operators = (
  "==" => { "cmp"=> sub { return shift eq shift; }, "build"=> sub { return shift; } },
  "!~" => { "cmp"=> sub { return shift !~ shift; }, "build"=> sub { my $x = shift; return qr/$x/; } },
  "=~" => { "cmp"=> sub { return shift =~ shift; }, "build"=> sub { my $x = shift; return qr/$x/; } },
);

my $dfwfw_conf;
my $container_by_ip;
my $container_by_id;
my $container_by_name;
my $container_extra_by_name;
my $network_by_name;
my $network_by_id;
my $network_by_bridge;


local $SIG{ALRM} = sub {
  mylog("Received alarm signal, rebuilding Docker configuration");
  ### Networks by name before: $network_by_name
  build_docker();
};
local $SIG{HUP} = sub {
  mylog("Received HUP signal, rebuilding everything");
  on_hup();
  build_firewall_ruleset();
};


on_hup();

init_dfwfw_rules();

monitor_changes();

sub on_hup {
  build_dfwfw_conf();
  build_docker();
  init_user_rules();
}


sub dfwfw_already_initiated {
   my $chain = shift;
   my $table = shift || "filter";
   return 0 == system("iptables -n -t $table --list $chain >/dev/null 2>&1");
}

sub dfwfw_rules_head {
  my $cat = shift;
  my $stateful = shift;

  my $re = "################ $cat head:
-F $cat
";
$re.= "-A $cat -m state --state INVALID -j DROP
-A $cat -m state --state RELATED,ESTABLISHED -j ACCEPT
" if($stateful);

  $re .= "\n";

  return $re;
}

sub dfwfw_rules_tail {
  my $cat = shift;
  return "" if($cat eq "DFWFW_INPUT"); # exception

  return "################ $cat tail:
-A $cat -j DROP

";
}

sub init_user_rules {
  return if(!$dfwfw_conf->{'initialization'});

  for my $table (keys %{$dfwfw_conf->{'initialization'}}) {
      validate_table($table);

      my $rules = "";
      for my $l (@{$dfwfw_conf->{'initialization'}->{$table}}) {
         $rules .= "$l\n";
      }
      iptables_commit($table, $rules);
  }
}

sub init_dfwfw_rules {


   if (!dfwfw_already_initiated("DFWFW_FORWARD")) {
     mylog("DFWFW_FORWARD chain not found, initializing");

     iptables_commit("filter", <<'EOF');
:DFWFW_FORWARD - [0:0]
-I FORWARD -j DFWFW_FORWARD
EOF
   }

   if (!dfwfw_already_initiated("DFWFW_INPUT")) {
     mylog("DFWFW_INPUT chain not found, initializing");

     iptables_commit("filter", <<'EOF');
:DFWFW_INPUT - [0:0]
-I INPUT -j DFWFW_INPUT
EOF
   }


   if (!dfwfw_already_initiated("DFWFW_POSTROUTING", "nat")) {
     mylog("DFWFW_POSTROUTING chain not found, initializing");

     iptables_commit("nat", <<"EOF");
:DFWFW_POSTROUTING - [0:0]
-I POSTROUTING -j DFWFW_POSTROUTING
-F DFWFW_POSTROUTING
-I DFWFW_POSTROUTING -o $dfwfw_conf->{'external_network_interface'} -j MASQUERADE
EOF

   }


   if (!dfwfw_already_initiated("DFWFW_PREROUTING", "nat")) {
     mylog("DFWFW_PREROUTING chain not found, initializing");

     iptables_commit("nat", <<"EOF");
:DFWFW_PREROUTING - [0:0]
-I PREROUTING -j DFWFW_PREROUTING
EOF

   }


}


sub event_cb {
   my $d = shift;

   return if($d->{'status'} !~ /^(start|die)$/);

   mylog("Docker event: $d->{'status'} of $d->{'from'}");
   build_docker();
   build_firewall_ruleset();
}

sub headers_cb {
   # first time headers arrived from the docker daemon

   build_firewall_ruleset();

}


sub monitor_changes {
   my $api = WebService::Docker->new($dfwfw_conf->{'docker_socket'});

   $api->set_headers_callback(\&headers_cb);
   $api->events(\&event_cb);
}

sub build_container_to_container_rule_network {
  my $rule = shift;
  my $network = shift;
  my $re = shift;

  ### c2c rule network: $rule->{'no'}

  my $src = [""];
  if($rule->{'src_container-ref'}) {
     $src = filter_hash_by_ref($rule->{'src_container-ref'}, $network->{'ContainerList'});
     if(!scalar @$src) {
        mylog("Container to container: src_container of rule #$rule->{'no'} does not match any containers, skipping rule");
        return "" ;
     }

  }

  my $dst = [""];
  if($rule->{'dst_container-ref'}) {
     $dst = filter_hash_by_ref($rule->{'dst_container-ref'}, $network->{'ContainerList'});
     if(!scalar @$dst) {
        mylog("Container to container: dst_container of rule #$rule->{'no'} does not match any containers, skipping rule");
        return ;
     }
  }

  for my $s (@$src) {
     for my $d (@$dst) {
         my $sstr = ($s ? "-s $s" : "");
         my $sstrcomment = ($s ? "from:".$container_by_ip->{$s}->{'Name'} : "");
         my $dstr = ($d ? "-d $d" : "");
         my $dstrcomment = ($d ? "to:".$container_by_ip->{$d}->{'Name'} : "");

         if(($sstrcomment)||($dstrcomment)) {
            $re->{'filter'} .= "# #$rule->{'no'}: $sstrcomment $dstrcomment\n";
         }
         $re->{'filter'} .= "-A DFWFW_FORWARD -i $network->{'BridgeName'} -o $network->{'BridgeName'} $sstr $dstr $rule->{'filter'} -j $rule->{'action'}\n";
     }
  }

}

sub match {
  my ($ref, $node) = @_;

  my $value = $node->{ $ref->{'field'} };
  if(!defined($value)){
     # this might be possible when a (dead) container is not yet detached from a network

     ### $ref->{'field'} not defined in: $node
     return;
  }

  return 1 if($ref->{'opcb'}($value, $ref->{'value'}));

}


sub filter_networks_by_ref {
  my $ref = shift;
  my @nets = values %$network_by_name;
  return filter_array_by_ref($ref, \@nets);
}

sub filter_array_by_ref {
  my $ref = shift;
  my $list = shift;

  my @re;
  for my $c (@$list) {
     next if(!match($ref, $c));

     push @re, $c;
  }

  return \@re;
}

sub filter_hash_by_ref {
  my $ref = shift;
  my $list = shift;

  my @re;
  for my $key (keys %$list) {
     my $field = $ref->{'field'};
     ### matching hash by ref: $key
     ###  for: $field
     next if(!match($ref, $list->{$key}));

     push @re, $key;
  }

  return \@re;
}



sub build_container_to_wider_world_rule_network {
  my $rule = shift;
  my $network = shift;
  my $re= shift;

  ### c2ww rule network: $rule->{'no'}

  my $src = [""];
  if($rule->{'src_container-ref'}) {
     $src = filter_hash_by_ref($rule->{'src_container-ref'}, $network->{'ContainerList'});
     if(!scalar @$src) {
        mylog("Container to wider world: src_container of rule #$rule->{'no'} does not match any containers, skipping rule");
        return ;
     }

  }

  for my $s (@$src) {
         my $sstr = ($s ? "-s $s" : "");
         my $sstrcomment = ($s ? "from:".$container_by_ip->{$s}->{'Name'} : "");

         if($sstrcomment) {
            $re->{'filter'} .= "# #$rule->{'no'}: $sstrcomment\n";
         }
         $re->{'filter'} .= "-A DFWFW_FORWARD -i $network->{'BridgeName'} -o $dfwfw_conf->{'external_network_interface'} $sstr $rule->{'filter'} -j $rule->{'action'}\n";
  }

}


sub build_container_to_host_rule_network {
  my $rule = shift;
  my $network = shift;
  my $re= shift;

  ### c2h rule network: $rule->{'no'}

  my $src = [""];
  if($rule->{'src_container-ref'}) {
     $src = filter_hash_by_ref($rule->{'src_container-ref'}, $network->{'ContainerList'});
     if(!scalar @$src) {
        mylog("Container to host: src_container of rule #$rule->{'no'} does not match any containers, skipping rule");
        return ;
     }

  }

  for my $s (@$src) {
         my $sstr = ($s ? "-s $s" : "");
         my $sstrcomment = ($s ? "from:".$container_by_ip->{$s}->{'Name'} : "");

         if($sstrcomment) {
            $re->{'filter'} .= "# #$rule->{'no'}: $sstrcomment\n";
         }
         $re->{'filter'} .= "-A DFWFW_INPUT -i $network->{'BridgeName'} $sstr $rule->{'filter'} -j $rule->{'action'}\n";
  }

}


sub build_wider_world_to_container_rule_network_container_expose {
  my $rule = shift;
  my $network = shift;
  my $re= shift;

  my $d = shift;
  my $expose = shift;

  my $cname = $container_by_ip->{$d}->{'Name'};

   for my $ep (@$expose) {
       my $cmnt = "# #$rule->{'no'}: host:$ep->{'host_port'} -> $cname:$ep->{'container_port'} / $ep->{'family'}\n";
       $re->{'nat'} .= $cmnt;
       $re->{'nat'} .= "-A DFWFW_PREROUTING -i $dfwfw_conf->{'external_network_interface'} -p $ep->{'family'} --dport $ep->{'host_port'} $rule->{'filter'} -j DNAT --to-destination $d:$ep->{'container_port'}\n";

       $re->{'filter'} .= $cmnt;
       $re->{'filter'} .= "-A DFWFW_FORWARD -i $dfwfw_conf->{'external_network_interface'} -o $network->{'BridgeName'} -d $d -p $ep->{'family'} --dport $ep->{'container_port'} -j ACCEPT\n";
   }

}

sub build_wider_world_to_container_rule_network {
  my $rule = shift;
  my $network = shift;
  my $re= shift;

  ### ww2c rule network: $rule->{'no'}

  if(!$rule->{'dst_container-ref'}) {
      mylog("Wider world to container: dst_container not specified in rule #$rule->{'no'}, skipping rule");
      return;
  }

  my $dst = filter_hash_by_ref($rule->{'dst_container-ref'}, $network->{'ContainerList'});
  if(!scalar @$dst) {
    mylog("Wider world to container: dst_container of rule #$rule->{'no'} does not match any containers, skipping rule");
    return ;
  }



  for my $d (@$dst) {

     my $expose = $rule->{'expose_port'};

     if(!$expose) {
        my @e;
        ### building exposed ports based on the current docker configuration
        for my $port (@{$container_by_ip->{$d}->{'Ports'}}) {
            my %a;

            eval {
              die "No private port exposed?!" if(!$port->{'PrivatePort'});
              $port->{'Type'} = "tcp" if(!$port->{'Type'});

              $a{'container_port'} = $port->{'PrivatePort'};
              $a{'host_port'} = $port->{'PublicPort'} ? $port->{'PublicPort'} : $port->{'PrivatePort'};
              $a{'family'} = $port->{'Type'};

              die "Autoconfiguration of IP specific exposed ports are not yet implemented" if(($port->{'IP'})&&($port->{'IP'} ne "0.0.0.0"));

              push @e, \%a;

            };
            warn $@ if($@);
        }
        $expose = \@e;

     }

     build_wider_world_to_container_rule_network_container_expose($rule, $network, $re, $d, $expose);
  }

}



sub build_firewall_rules_category_rule {
  my $category = shift;
  my $rule_builder_cb = shift;
  my $rule = shift;
  my $re = shift;

  my $matching_nets = filter_networks_by_ref($rule->{'network-ref'});
  mylog("$category: number of matching networks for rule #$rule->{'no'}: ".(scalar @$matching_nets));

  for my $net (@$matching_nets) {

     $rule_builder_cb->($rule, $net, $re);
  }

}


sub build_firewall_rules_category {
  my $category = shift;
  my $rule_builder_cb = shift;
  my $re = shift;

  my %sre;
  if($dfwfw_conf->{$category}->{'rules'})
  {

    for my $rule (@{$dfwfw_conf->{$category}->{'rules'}}) {

         next if($rule->{'broken'});

         build_firewall_rules_category_rule ($category, $rule_builder_cb, $rule, \%sre);

    }

  }

  for my $k (keys %sre) {
     $re->{$k} .= "################ $category:\n$sre{$k}\n\n"  if($sre{$k});
  }

}

sub  build_firewall_rules_container_internal {
   return if(!$dfwfw_conf->{'container_internals'}->{'rules'});

   mylog("Rebuilding container internal firewall rulesets...");

   my %rules_to_commit;

   for my $rule (@{$dfwfw_conf->{'container_internals'}->{'rules'}}) {

       next if($rule->{'broken'});

       my $cts = filter_hash_by_ref($rule->{'container-ref'}, $container_by_name);
       if(!scalar @$cts) {
           mylog("Container internals: rule #$rule->{'no'} does not match any containers, skipping rule");
           next;
       }

       for my $ctname (@$cts) {
         $rules_to_commit{$ctname}{$rule->{'table'}} .= "# rule #$rule->{'no'}:\n";
         for my $iptables_line (@{$rule->{'rules'}}) {
            $rules_to_commit{$ctname}{$rule->{'table'}} .= "$iptables_line\n";
         }
         $rules_to_commit{$ctname}{$rule->{'table'}} .= "\n";
       }
   }

#  print Dumper(\%rules_to_commit);exit;

  for my $ctname (keys %rules_to_commit) {
     for my $table (keys %{$rules_to_commit{$ctname}}) {
         my $rules = $rules_to_commit{$ctname}{$table};

         my $pid = $container_extra_by_name->{$ctname}->{'State'}->{'Pid'};
         if($pid) {
            mylog("Commiting $table table rules for container $ctname via nsenter");
            iptables_commit($table, $rules, $pid);
         } else {
            mylog("Skipping commit for $ctname, we have no pid");
         }

     }
  }
}


sub build_firewall_ruleset {
  mylog("Rebuilding firewall ruleset...");

  my %rules;

  $rules{'filter'}  = dfwfw_rules_head("DFWFW_FORWARD", 1);
  $rules{'filter'} .= dfwfw_rules_head("DFWFW_INPUT");

  $rules{'nat'}     = dfwfw_rules_head("DFWFW_PREROUTING");

  build_firewall_rules_category("container_to_container", \&build_container_to_container_rule_network, \%rules);
  build_firewall_rules_category("container_to_wider_world", \&build_container_to_wider_world_rule_network, \%rules);

  build_firewall_rules_category("container_to_host", \&build_container_to_host_rule_network, \%rules);

  build_firewall_rules_category("wider_world_to_container", \&build_wider_world_to_container_rule_network, \%rules);

  # and the final rule just for sure.
  $rules{'filter'} .= dfwfw_rules_tail("DFWFW_FORWARD");

  for my $k ("filter", "nat") {
     next if(!$rules{$k});
     iptables_commit($k, $rules{$k});
  }

  build_firewall_rules_container_internal();

  if($c_one_shot) {
     mylog("Exiting, one-shot was specified");
     exit 0;
  }
}

sub parse_container_ref {
  my ($node, $refname) = @_;

  my $spec = $node->{$refname};
  return if(!$spec);

  $spec =~ s#\s*##g; # Invalid container name (...), only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed
  $spec = "Name==$spec"  if($spec !~ /(=|!~)/);
  die "Invalid syntax: ".$node->{$refname} if($spec !~ /^(Name|Id|IdShort)(==|=~|!~)(.+)/);

  $node->{"$refname-ref"} = {
     "field" => $1,
     "op" => $2,
     "opcb" => $operators{$2}{"cmp"},
     "value"=> $operators{$2}{"build"}($3),
  };

  return 1;

}


sub parse_network_ref {
  my ($node, $refname) = @_;

  my $spec = $node->{$refname};
  return if(!$spec);

  $spec =~ s#\s*##g; # Invalid container name (...), only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed
  $spec = "Name==$spec"  if($spec !~ /(=|!~)/);
  die "Invalid syntax: ".$node->{$refname} if($spec !~ /^(Name|Id|IdShort)(==|=~|!~)(.+)/);

  $node->{"$refname-ref"} = {
     "field" => $1,
     "op" => $2,
     "opcb" => $operators{$2}{"cmp"},
     "value"=> $operators{$2}{"build"}($3),
  };

  return 1;
}
sub action_test {
  my $node = shift;
  my $field = shift || "action";

  die "Invalid action" if((!$node->{$field})||($node->{$field} !~ /^(ACCEPT|DROP|REJECT|LOG)$/));
}

sub filter_test {
  my $node = shift;

  $node->{'filter'} = "" if(!$node->{'filter'});
}

sub parse_expose_port {
  my $rule = shift;

  return if(!$rule->{'expose_port'}); # would by exposed dynamically

  my $t = ref($rule->{'expose_port'});
  if($t eq "") {
     ### classical port definition, turning it into an array: $rule->{'expose_port'}

     $rule->{'expose_port'} = "$1/tcp" if($rule->{'expose_port'} =~ /^(\d+)$/);

     die "Invalid syntax of expose_port" if($rule->{'expose_port'} !~ m#^(\d+)/(tcp|udp)$#);
     $rule->{'expose_port'} = [{
         "container_port"=> $1,
         "host_port"=> $1,
         "family"=> $2,
     }];
  }elsif($t ne "ARRAY") {
    die "Invalid expose_port node";
  }

  for my $ep (@{$rule->{'expose_port'}}) {
     for my $k (keys %$ep) {
        die "Unknown node in expose_port: $k" if($k !~ /^(host_port|container_port|family)$/);
        my $v = $ep->{$k};
        die "Invalid port in expose_port: $v" if(($k =~ /_port/)&&($v !~ /^\d+$/));
        die "Invalid family in expose_port: $v" if(($k eq "family")&&($v !~ /^(tcp|udp)$/));
     }
     $ep->{'family'}="tcp" if(!$ep->{'family'});
  }

}


sub default_policy {
  my $cat = shift;
  my $force_default = shift;

  return if(($force_default)&&($force_default eq "-"));

  $dfwfw_conf->{$cat}->{'default_policy'} = $force_default if(($force_default)&&(!$dfwfw_conf->{$cat}->{'default_policy'}));

  if($dfwfw_conf->{$cat}->{'default_policy'}) {
     eval {
        action_test($dfwfw_conf->{$cat}, 'default_policy');
        push @{$dfwfw_conf->{$cat}->{'rules'}}, {
           "network"=> "Name =~ .*",
           "action"=> $dfwfw_conf->{$cat}->{'default_policy'},
        } if(($dfwfw_conf->{$cat}->{'default_policy'} ne "DROP")||($cat eq "container_to_host"));
     };
     if($@) {
        mylog("ERROR: invalid default policy for $cat: $@");
     }
  }

}

sub build_dfwfw_conf_rule_category {
  my $category = shift;
  my $force_default_policy = shift;
  my @extra_nodes = @_;

  my @generic_nodes = ("action","filter","network");
  my @nodes = (@generic_nodes, @extra_nodes);

  ### !!!!!!!!!!!!! category: $category
  ###               default policy: $force_default_policy

  default_policy($category, $force_default_policy);

  return if(!$dfwfw_conf->{$category}->{'rules'});

  if(scalar @{$dfwfw_conf->{$category}->{'rules'}}) {
     my $rno = 0;
     for my $node (@{$dfwfw_conf->{$category}->{'rules'}}) {
        eval {
           for my $k (keys %$node) {
              die "Invalid key: $k" if(!($k ~~ @nodes));
           }

           die "No network specified" if(!parse_network_ref($node, "network"));
           filter_test($node);

           for my $extra (@extra_nodes) {
              if($extra eq "action") {
                 action_test($node);
              }elsif($extra =~ /container/) {
                 parse_container_ref($node, $extra);
              }elsif($extra eq "expose_port") {
                 parse_expose_port($node);
              } else {
                 die "No parsing handler for: $extra";
              }
           }

        };
        $node->{'no'} = ++$rno;
        if($@) {
           mylog("ERROR: Broken rule: $@\n".Dumper($node));
           $node->{'broken'} = 1;
        }
     }

     mylog("$category rules were parsed as:\n".Dumper($dfwfw_conf->{$category}->{'rules'}));
  }

}

sub validate_table {
  my $table = shift;

  die "Invalid table" if(!($table ~~ IPTABLES_TABLES));
}


sub build_dfwfw_conf_container_internals {


  return if(!$dfwfw_conf->{"container_internals"});
  return if(!$dfwfw_conf->{"container_internals"}->{'rules'});
  return if(!scalar @{$dfwfw_conf->{"container_internals"}->{'rules'}});

  my @nodes = ("container","rules","table");

     my $rno = 0;
     for my $node (@{$dfwfw_conf->{"container_internals"}->{'rules'}}) {
        eval {
           for my $k (keys %$node) {
              die "Invalid key: $k" if(!($k ~~ @nodes));
           }

           die "Container not specified" if(!parse_container_ref($node, "container"));
           $node->{'table'}="filter" if(!$node->{'table'});

           validate_table($node->{'table'});

           die "No rules specified" if(!$node->{'rules'});
           my $t = ref($node->{'rules'});
           die "Invalid rule node" if($t !~ /^(ARRAY)?$/);

           $node->{'rules'} = [$node->{'rules'}] if($t eq "");

        };
        $node->{'no'} = ++$rno;
        if($@) {
           mylog("ERROR: Broken rule: $@\n".Dumper($node));
           $node->{'broken'} = 1;
        }
     }

     mylog("container internal rules were parsed as:\n".Dumper($dfwfw_conf->{"container_internals"}->{'rules'}));

}


sub build_dfwfw_conf {
  mylog("Parsing ruleset configuration file ".DFWFW_CONFIG);
  my $contents = read_file(DFWFW_CONFIG);
  # strip out comments:
  $contents =~ s/#.*//g;
  $dfwfw_conf = decode_json($contents);

  for my $k (keys %$dfwfw_conf) {
     warn "Unknown node in dfwfw.conf: $k" if($k !~ /^(docker_socket|external_network_interface|container_to_container|container_to_wider_world|container_to_host|wider_world_to_container|container_internal)$/);
  }

  $dfwfw_conf->{'external_network_interface'} = "eth0" if (!$dfwfw_conf->{'external_network_interface'});

  build_dfwfw_conf_rule_category("container_to_container",   undef, "action","src_container", "dst_container");
  build_dfwfw_conf_rule_category("container_to_wider_world", undef, "action","src_container");
  build_dfwfw_conf_rule_category("container_to_host",        "DROP","action","src_container");

  build_dfwfw_conf_rule_category("wider_world_to_container", "-",   "expose_port", "dst_container");

  build_dfwfw_conf_container_internals();

}

sub build_docker {

  mylog("Talking to Docker daemon to learn current network and container configuration");

  $container_by_ip = {};
  $container_by_id = {};
  $container_by_name = {};
  $container_extra_by_name = {};
  $network_by_name = {};
  $network_by_id = {};
  $network_by_bridge = {};


  my $api = WebService::Docker->new($dfwfw_conf->{'docker_socket'});
  my $networks = $api->networks();
  my $containers = $api->containers();

  for my $cont (@$containers) {

     $cont->{'IdShort'} = substr($cont->{'Id'}, 0, 12);

     $container_by_id->{$cont->{'Id'}} = $cont;
     for my $name (@{$cont->{'Names'}}) {
        $name =~ s#^/*##;
        $container_by_name->{$name} = $cont;
        $cont->{'Name'} = $name;
     }

     %{$cont->{'NetworkList'}} = ();
  }
  for my $net (@$networks) {
     next if($net->{'Driver'} ne "bridge");

     $net->{'IdShort'} = substr($net->{'Id'}, 0, 12);
     $net->{'BridgeName'} = $net->{'Options'}->{"com.docker.network.bridge.name"} ? $net->{'Options'}->{"com.docker.network.bridge.name"} : "br-".$net->{'IdShort'};


     %{$net->{'ContainerList'}} = ();
     for my $cid (keys %{$net->{'Containers'}}) {
        my $cont = $container_by_id->{$cid};

        my $ipv4 =  $net->{'Containers'}->{$cid}->{'IPv4Address'};
        $ipv4 =~ s#^(.+)/\d+$#$1#;

        $net->{'ContainerList'}->{$ipv4} = $cont;
        $cont->{'NetworkList'}->{$ipv4} = $net;

        $container_by_ip->{$ipv4} = $cont;
     }

     $network_by_name->{$net->{'Name'}} = $net;
     $network_by_id->{$net->{'Id'}} = $net;
     $network_by_bridge->{$net->{'BridgeName'}} = $net;
  }

  if(($dfwfw_conf->{'container_internals'}->{'rules'})&&(scalar @{$dfwfw_conf->{'container_internals'}->{'rules'}})) {
     for my $name (keys %$container_by_name) {
        my $c = $container_by_name->{$name};
        my $full_info = $api->container_info($c->{'Id'});
        $container_extra_by_name->{$name} = $full_info;
     }
  }

=debug display:
  print Dumper($network_by_name);
  print Dumper($container_by_id);
  print Dumper($container_by_name);
  print Dumper($container_extra_by_name);
  exit;
=cut
  ### Networks by name: $network_by_name
}

sub iptables_commit {
  my ($table, $rules, $pid_for_nsenter) = @_;

  my $complete = "
*$table
$rules
COMMIT
";
  $complete =~ s/ {2,}/ /g;

  mylog(($c_dry_run ? "Dry-run, not " : ""). "commiting to $table table".($pid_for_nsenter?" via nsenter for pid $pid_for_nsenter":"").":\n$complete\n");


  if(!$c_dry_run) {
     write_file(IPTABLES_TMP_FILE, $complete);

     my $cmd_prefix = $pid_for_nsenter ? "nsenter -t $pid_for_nsenter -n" : "";
     system("$cmd_prefix iptables-restore -c --noflush ".IPTABLES_TMP_FILE);

     unlink(IPTABLES_TMP_FILE);
  }
}

sub mylog {
  my $msg = shift;

  print ("[".localtime."] $msg\n");
}
