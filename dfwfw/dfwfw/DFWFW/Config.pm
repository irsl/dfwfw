package DFWFW::Config;

use strict;
use warnings;
use JSON::XS;
use Data::Dumper;
use experimental 'smartmatch';
use File::Slurp;
use constant DFWFW_CONFIG => "/etc/dfwfw.conf";
use DFWFW::Iptables;

my %operators = (
  "==" => { "cmp"=> sub { return shift eq shift; }, "build"=> sub { return shift; } },
  "!~" => { "cmp"=> sub { return shift !~ shift; }, "build"=> sub { my $x = shift; return qr/$x/; } },
  "=~" => { "cmp"=> sub { return shift =~ shift; }, "build"=> sub { my $x = shift; return qr/$x/; } },
);


sub parse_container_ref {
  my $dfwfw_conf = shift;
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


sub _parse_network_ref {
  my $dfwfw_conf = shift;
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
sub _action_test {
  my $dfwfw_conf = shift;
  my $node = shift;
  my $field = shift || "action";

  die "Invalid action" if((!$node->{$field})||($node->{$field} !~ /^(ACCEPT|DROP|REJECT|LOG)$/));
}

sub _filter_test {
  my $dfwfw_conf = shift;
  my $node = shift;

  $node->{'filter'} = "" if(!$node->{'filter'});
}

sub _parse_expose_port {
  my $dfwfw_conf = shift;
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


sub _default_policy {
  my $dfwfw_conf = shift;
  my $cat = shift;
  my $force_default = shift;

  return if(($force_default)&&($force_default eq "-"));

  $dfwfw_conf->{$cat}->{'default_policy'} = $force_default if(($force_default)&&(!$dfwfw_conf->{$cat}->{'default_policy'}));

  if($dfwfw_conf->{$cat}->{'default_policy'}) {
     eval {
        $dfwfw_conf->_action_test($dfwfw_conf->{$cat}, 'default_policy');
        push @{$dfwfw_conf->{$cat}->{'rules'}}, {
           "network"=> "Name =~ .*",
           "action"=> $dfwfw_conf->{$cat}->{'default_policy'},
        } if(($dfwfw_conf->{$cat}->{'default_policy'} ne "DROP")||($cat eq "container_to_host"));
     };
     if($@) {
        die "ERROR: invalid default policy for $cat: $@";
     }
  }

}

sub _parse_dfwfw_conf_rule_category {
  my $dfwfw_conf = shift;
  my $category = shift;
  my $force_default_policy = shift;
  my @extra_nodes = @_;

  my @generic_nodes = ("action","filter","network");
  my @nodes = (@generic_nodes, @extra_nodes);

  ### !!!!!!!!!!!!! category: $category
  ###               default policy: $force_default_policy

  $dfwfw_conf->_default_policy($category, $force_default_policy);

  return if(!$dfwfw_conf->{$category}->{'rules'});

  if(scalar @{$dfwfw_conf->{$category}->{'rules'}}) {
     my $rno = 0;
     for my $node (@{$dfwfw_conf->{$category}->{'rules'}}) {

           for my $k (keys %$node) {
              die "Invalid key: $k" if(!($k ~~ @nodes));
           }

           die "No network specified" if(!$dfwfw_conf->_parse_network_ref($node, "network"));
           $dfwfw_conf->_filter_test($node);

           for my $extra (@extra_nodes) {
              if($extra eq "action") {
                 $dfwfw_conf->_action_test($node);
              }elsif($extra =~ /container/) {
                 $dfwfw_conf->parse_container_ref($node, $extra);
              }elsif($extra eq "expose_port") {
                 $dfwfw_conf->_parse_expose_port($node);
              } else {
                 die "No parsing handler for: $extra";
              }
           }

        $node->{'no'} = ++$rno;
     }

     $dfwfw_conf->{'_logger'}->("$category rules were parsed as:\n".Dumper($dfwfw_conf->{$category}->{'rules'}));
  }

}



sub _parse_dfwfw_conf_container_internals {
  my $dfwfw_conf = shift;

  return if(!$dfwfw_conf->{"container_internals"});
  return if(!$dfwfw_conf->{"container_internals"}->{'rules'});
  return if(!scalar @{$dfwfw_conf->{"container_internals"}->{'rules'}});

  my @nodes = ("container","rules","table");

     my $rno = 0;
     for my $node (@{$dfwfw_conf->{"container_internals"}->{'rules'}}) {

           for my $k (keys %$node) {
              die "Invalid key: $k" if(!($k ~~ @nodes));
           }

           die "Container not specified" if(!$dfwfw_conf->parse_container_ref($node, "container"));
           $node->{'table'}="filter" if(!$node->{'table'});

           DFWFW::Iptables->validate_table($node->{'table'});

           die "No rules specified" if(!$node->{'rules'});
           my $t = ref($node->{'rules'});
           die "Invalid rule node" if($t !~ /^(ARRAY)?$/);

           $node->{'rules'} = [$node->{'rules'}] if($t eq "");

        $node->{'no'} = ++$rno;
     }

     $dfwfw_conf->{'_logger'}->("container internal rules were parsed as:\n".Dumper($dfwfw_conf->{"container_internals"}->{'rules'}));

}


sub _parse_dfwfw_conf_container_aliases {
  my $dfwfw_conf = shift;

  return if(!$dfwfw_conf->{"container_aliases"});
  return if(!$dfwfw_conf->{"container_aliases"}->{'rules'});
  return if(!scalar @{$dfwfw_conf->{"container_aliases"}->{'rules'}});

  my @nodes = ("aliased_container","alias_name","receiver_network","receiver_containers");

     my $rno = 0;
     for my $node (@{$dfwfw_conf->{"container_aliases"}->{'rules'}}) {

           for my $k (keys %$node) {
              die "Invalid key: $k" if(!($k ~~ @nodes));
           }

           die "Aliased container not specified" if(!$dfwfw_conf->parse_container_ref($node, "aliased_container"));
           die "Receiver containers not specified" if(!$dfwfw_conf->parse_container_ref($node, "receiver_containers"));
           die "No network specified" if(!$dfwfw_conf->_parse_network_ref($node, "receiver_network"));

           die "Name of the alias not defined" if(!$node->{'alias_name'});

        $node->{'no'} = ++$rno;
     }

     $dfwfw_conf->{'_logger'}->("container aliases were parsed as:\n".Dumper($dfwfw_conf->{"container_aliases"}->{'rules'}));

}

sub new {
  my $class = shift;
  my $mylog = shift;
  my $config_file = shift || DFWFW_CONFIG;

  die "No config file" if(!$config_file);
  die "No log callback" if(!$mylog);

    $mylog->("Parsing ruleset configuration file $config_file");
    my $contents = read_file($config_file);

    # strip out comments:
    $contents =~ s/#.*//g;

    my $dfwfw_conf = bless decode_json($contents), $class;
    $dfwfw_conf->{'_logger'}= $mylog;

    for my $k (keys %$dfwfw_conf) {
       $dfwfw_conf->{'_logger'}->( "Unknown node in dfwfw.conf: $k" ) if($k !~ /^(initialization|docker_socket|external_network_interface|container_to_container|container_to_wider_world|container_to_host|wider_world_to_container|container_internals|container_aliases|_logger)$/);
    }

    $dfwfw_conf->{'external_network_interface'} = "eth0" if (!$dfwfw_conf->{'external_network_interface'});

    $dfwfw_conf->_parse_dfwfw_conf_rule_category("container_to_container",   undef, "action","src_container", "dst_container");
    $dfwfw_conf->_parse_dfwfw_conf_rule_category("container_to_wider_world", undef, "action","src_container");
    $dfwfw_conf->_parse_dfwfw_conf_rule_category("container_to_host",        "DROP","action","src_container");

    $dfwfw_conf->_parse_dfwfw_conf_rule_category("wider_world_to_container", "-",   "expose_port", "dst_container");

    $dfwfw_conf->_parse_dfwfw_conf_container_internals();

    $dfwfw_conf->_parse_dfwfw_conf_container_aliases();

  return $dfwfw_conf;
}


1;
