#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Data::Dumper;
use FindBin qw($Bin);
use JSON::XS;
use Getopt::Long;

BEGIN {
 push @INC, "$Bin";
}
use WebService::Docker;
use Config::HostsFile;
use DFWFW::Config;
use DFWFW::Iptables;

local $| = 1;


my ($c_dry_run, $c_one_shot) = (0, 0);

  GetOptions ("dry-run" => \$c_dry_run,
              "one-shot"   => \$c_one_shot)
  or die("Usage: $0 [--dry-run] [--one-shot]");


my $dfwfw_conf;
my $iptables = new DFWFW::Iptables(\&mylog, $c_dry_run);

my $container_by_ip;
my $container_by_id;
my $container_by_name;
my $container_extra_by_name;
my $network_by_name;
my $network_by_id;
my $network_by_bridge;

local $SIG{TERM} = sub {
  mylog("Received term signal, exiting");
  exit;
};
local $SIG{ALRM} = sub {
  mylog("Received alarm signal, rebuilding Docker configuration");
  ### Networks by name before: $network_by_name
  fetch_docker_configuration();
};
local $SIG{HUP} = sub {
  mylog("Received HUP signal, rebuilding everything");
  return if(!on_hup(1));

  rebuild();
};


on_hup();

init_dfwfw_rules();

monitor_changes();

sub on_hup {
  my $safe = shift;

  return if(!parse_dfwfw_conf($safe));

  fetch_docker_configuration();
  init_user_rules();

  return 1;
}

sub rebuild {
  # this sub is called usually in context of LWP which hides the default exception outputs, so we workaround it here:
  eval {
    build_firewall_ruleset();
    build_container_aliases();
  };
  if($@) {
     mylog($@);
     die($@);
  }

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
      DFWFW::Iptables->validate_table($table);

      my $rules = "";
      for my $l (@{$dfwfw_conf->{'initialization'}->{$table}}) {
         $rules .= "$l\n";
      }
      $iptables->commit($table, $rules);
  }
}

sub init_dfwfw_rules {


   if (!dfwfw_already_initiated("DFWFW_FORWARD")) {
     mylog("DFWFW_FORWARD chain not found, initializing");

     $iptables->commit("filter", <<'EOF');
:DFWFW_FORWARD - [0:0]
-I FORWARD -j DFWFW_FORWARD
EOF
   }

   if (!dfwfw_already_initiated("DFWFW_INPUT")) {
     mylog("DFWFW_INPUT chain not found, initializing");

     $iptables->commit("filter", <<'EOF');
:DFWFW_INPUT - [0:0]
-I INPUT -j DFWFW_INPUT
EOF
   }


   if (!dfwfw_already_initiated("DFWFW_POSTROUTING", "nat")) {
     mylog("DFWFW_POSTROUTING chain not found, initializing");

     $iptables->commit("nat", <<"EOF");
:DFWFW_POSTROUTING - [0:0]
-I POSTROUTING -j DFWFW_POSTROUTING
-F DFWFW_POSTROUTING
-I DFWFW_POSTROUTING -o $dfwfw_conf->{'external_network_interface'} -j MASQUERADE
EOF

   }


   if (!dfwfw_already_initiated("DFWFW_PREROUTING", "nat")) {
     mylog("DFWFW_PREROUTING chain not found, initializing");

     $iptables->commit("nat", <<"EOF");
:DFWFW_PREROUTING - [0:0]
-I PREROUTING -j DFWFW_PREROUTING
EOF

   }


}


sub event_cb {
   my $d = shift;

   return if($d->{'status'} !~ /^(start|die)$/);

   mylog("Docker event: $d->{'status'} of $d->{'from'}");
   fetch_docker_configuration();

   rebuild();
}

sub headers_cb {
   # first time HTTP headers arrived from the docker daemon
   # this is a tricky solution to reach a race condition free state

   rebuild();

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

sub filter_hash_by_name {
  my $name = shift;
  my $list = shift;

  my %n = ("name"=> "Name == $name");
  $dfwfw_conf->parse_container_ref(\%n, "name");

  return filter_hash_by_ref($n{"name-ref"}, $list);
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

sub build_container_aliases {

   return if(!$dfwfw_conf->{'container_aliases'}->{'rules'});

   mylog("Rebuilding container aliases...");

   my %host_files;
   for my $rule (@{$dfwfw_conf->{'container_aliases'}->{'rules'}}) {

       my $alias_name = $rule->{'alias_name'};
       mylog("Alias wanted: $alias_name");

       my $cts = filter_hash_by_ref($rule->{'aliased_container-ref'}, $container_by_name);
       if(!scalar @$cts) {
           mylog("Container aliases: rule #$rule->{'no'} does not match any aliased containers, skipping rule");
           next;
       }

       for my $ctname (@$cts) {

           mylog ("Aliased container: $ctname");

           my $matching_nets = filter_networks_by_ref($rule->{'receiver_network-ref'});
           for my $net (@{$matching_nets}) {
               my $alias_matches = filter_hash_by_name($ctname, $net->{'ContainerList'});
               # print Dumper(\keys %{$net->{'ContainerList'}}); print Dumper($alias_matches);exit;
               if(scalar @$alias_matches != 1) {
                  mylog("it seems the aliased container is not in this network: ".Dumper($alias_matches));
                  next;
               }
               my $alias_ip = $alias_matches->[0];

               mylog ("Aliased container: $ctname ($alias_ip), receiver network: $net->{'Name'}");


               my $receiver_containers = filter_hash_by_ref($rule->{'receiver_containers-ref'}, $net->{'ContainerList'});
               for my $receiver_ip (@{$receiver_containers}) {
                  my $receiver = $net->{'ContainerList'}->{$receiver_ip};
                  my $receiver_name = $receiver->{'Name'};
                  mylog ("Aliased container: $ctname ($alias_ip), receiver network: $net->{'Name'}, receiver container: $receiver_name ($receiver_ip)");

                  my $hosts_file =  $container_extra_by_name->{$receiver_name}->{'HostsPath'};
                  if(!$hosts_file) {
                        mylog("Woho, we can't seem to find the hosts file of this container");
                        ### Dumper( $container_extra_by_name );
                        next;
                  }

                  if(!defined($host_files{$hosts_file})) {
                      mylog("Opening hosts file $hosts_file for $receiver_name");
                      $host_files{$hosts_file} = new Config::HostsFile($hosts_file);
                  }

                  $host_files{$hosts_file}->update_host($alias_name, $alias_ip);
               }

           }

       }

   }

   for my $hf (keys %host_files) {
       mylog("Flushing hosts file: ".$hf);
       $host_files{$hf}->flush();
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


         build_firewall_rules_category_rule ($category, $rule_builder_cb, $rule, \%sre);

    }

  }

  for my $k (keys %sre) {
     $re->{$k} .= "################ $category:\n$sre{$k}\n\n"  if($sre{$k});
  }

}

sub  build_firewall_rules_container_internals {
   return if(!$dfwfw_conf->{'container_internals'}->{'rules'});

   mylog("Rebuilding container internal firewall rulesets...");

   my %rules_to_commit;

   for my $rule (@{$dfwfw_conf->{'container_internals'}->{'rules'}}) {


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
            $iptables->commit($table, $rules, $pid);
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
     $iptables->commit($k, $rules{$k});
  }

  build_firewall_rules_container_internals();

  if($c_one_shot) {
     mylog("Exiting, one-shot was specified");
     exit 0;
  }
}



sub parse_dfwfw_conf {
  my $safe = shift;

  eval {
     my $new_dfwfw_conf = new DFWFW::Config(\&mylog);
     # success
     $dfwfw_conf = $new_dfwfw_conf;
  }; 
  if($@) {
     if($safe) {
         print "Syntax error in configuration file:\n$@\n\nReverting to original config and not proceeding to firewall ruleset rebuild\n";
         return 0;
     }

     die $@;
  }

  return 1;
}

sub fetch_docker_configuration {

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

  if(
     (($dfwfw_conf->{'container_internals'}->{'rules'})&&(scalar @{$dfwfw_conf->{'container_internals'}->{'rules'}})) 
     ||
     (($dfwfw_conf->{'container_aliases'}->{'rules'})&&(scalar @{$dfwfw_conf->{'container_aliases'}->{'rules'}})) 
    )
  {
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

sub mylog {
  my $msg = shift;

  print ("[".localtime."] $msg\n");
}
