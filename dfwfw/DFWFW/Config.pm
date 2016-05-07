package DFWFW::Config;

use strict;
use warnings;
use PreJSON::Parser;
use IO::Interface::Simple;
use Data::Dumper;
use experimental 'smartmatch';
use File::Slurp;
use constant DFWFW_CONFIG_LEGACY => "/etc/dfwfw.conf";
use constant DFWFW_CONFIG => "/etc/dfwfw/dfwfw.conf";
use DFWFW::Iptables;
use DFWFW::RuleSet::UserInit;
use DFWFW::RuleSet::ContainerToContainer;
use DFWFW::RuleSet::ContainerToWiderWorld;
use DFWFW::RuleSet::ContainerToHost;
use DFWFW::RuleSet::WiderWorldToContainer;
use DFWFW::RuleSet::ContainerDnat;
use DFWFW::RuleSet::ContainerInternal;
use DFWFW::RuleSet::ContainerAlias;

my %operators = (
  "==" => { "cmp"=> sub { return shift eq shift; }, "build"=> sub { return shift; } },
  "!~" => { "cmp"=> sub { return shift !~ shift; }, "build"=> sub { my $x = shift; return qr/$x/; } },
  "=~" => { "cmp"=> sub { return shift =~ shift; }, "build"=> sub { my $x = shift; return qr/$x/; } },
);


sub parse_container_ref {
  my $dfwfw_conf_class = shift;
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
  my $dfwfw_conf_class = shift;
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



sub parse_expose_port {
  my $dfwfw_conf_class = shift;
  my $rule = shift;

  return if(!$rule->{'expose_port'}); # will be exposed dynamically

  my $t = ref($rule->{'expose_port'});
  if($t eq "") {
     ### classical port definition, turning it into an array: $rule->{'expose_port'}

     $rule->{'expose_port'} = "$1/tcp" if($rule->{'expose_port'} =~ /^(\d+)$/);

     die "Invalid syntax of expose_port" if($rule->{'expose_port'} !~ m#^(\d+(?::\d+)?)/(tcp|udp)$#);
     $rule->{'expose_port'} = [{
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
        die "Invalid host_port in expose_port: $v" if(($k =~ /_port/)&&($v !~ /^\d+(:\d+)?$/));
        die "Invalid container_port in expose_port: $v" if(($k =~ /container_port/)&&($v !~ /^\d+$/));
        die "Invalid family in expose_port: $v" if(($k eq "family")&&($v !~ /^(tcp|udp)$/));
     }
     $ep->{'family'}="tcp" if(!$ep->{'family'});
  }

}


sub filter_test {
  my $dfwfw_conf_class = shift;
  my $node = shift;

  $node->{'filter'} = "" if(!$node->{'filter'});
}


sub action_test {
  my $dfwfw_conf_class = shift;
  my $node = shift;
  my $field = shift || "action";

  die "Invalid action" if((!$node->{$field})||($node->{$field} !~ /^(ACCEPT|DROP|REJECT|LOG)$/));
}


sub mylog {
  my $obj = shift;
  my $msg = shift;

  $obj->{'_logger'}->($msg);
}

sub _turn_to_ruleset {
  my $dfwfw_conf = shift;
  my $key = shift;
  my $ruleset = shift;

  $ruleset->parse($key);
  $dfwfw_conf->{$key} = $ruleset;
  $dfwfw_conf->mylog("$key was parsed as:\n".$ruleset->info());
}

sub new {
  my $class = shift;
  my $mylog = shift;
  my $config_file = shift;

  if(!$config_file) {
     $config_file = DFWFW_CONFIG_LEGACY;
     $config_file = DFWFW_CONFIG if(-s DFWFW_CONFIG);
  }

  die "No config file" if(!$config_file);
  die "No log callback" if(!$mylog);

    $mylog->("Parsing ruleset configuration file $config_file");
    my $contents = read_file($config_file);

    my $dfwfw_conf = bless PreJSON::Parser::decode($contents, sub{
       my ($k, $v) = @_;
       if($k eq "interface_ip") {
          my $if1   = IO::Interface::Simple->new($v);
          return $if1->address;
       }

    }), $class;

    $dfwfw_conf->{'_logger'} = $mylog;

    for my $k (keys %$dfwfw_conf) {
       $dfwfw_conf->mylog( "Unknown node in dfwfw.conf: $k" ) if($k !~ /^(initialization|log_path|log_split_by_event|docker_socket|external_network_interface|container_to_container|container_to_wider_world|container_to_host|wider_world_to_container|container_dnat|container_internals|container_aliases|_logger)$/);
    }

    $dfwfw_conf->{'external_network_interface'} = "eth0" if (!$dfwfw_conf->{'external_network_interface'});

    $dfwfw_conf->_turn_to_ruleset("initialization", new DFWFW::RuleSet::UserInit($dfwfw_conf));

    $dfwfw_conf->_turn_to_ruleset("container_to_container", new DFWFW::RuleSet::ContainerToContainer($dfwfw_conf));
    $dfwfw_conf->_turn_to_ruleset("container_to_wider_world", new DFWFW::RuleSet::ContainerToWiderWorld($dfwfw_conf));
    $dfwfw_conf->_turn_to_ruleset("container_to_host", new DFWFW::RuleSet::ContainerToHost($dfwfw_conf));
    $dfwfw_conf->_turn_to_ruleset("wider_world_to_container", new DFWFW::RuleSet::WiderWorldToContainer($dfwfw_conf));
    $dfwfw_conf->_turn_to_ruleset("container_dnat", new DFWFW::RuleSet::ContainerDnat($dfwfw_conf));
    $dfwfw_conf->_turn_to_ruleset("container_internals", new DFWFW::RuleSet::ContainerInternal($dfwfw_conf));
    $dfwfw_conf->_turn_to_ruleset("container_aliases", new DFWFW::RuleSet::ContainerAlias($dfwfw_conf));

  return $dfwfw_conf;
}


1;
