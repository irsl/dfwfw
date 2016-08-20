package DFWFW::Fire;

use strict;
use warnings;

use DFWFW::Iptables;
use WebService::Docker::Info;

sub new {
  my $class = shift;
  my $mylog = shift;
  my $iptables = shift;

  my $re = {
    "_logger" => $mylog,
    "_iptables"=> $iptables,
  };
  my $bre = bless $re, $class;

  return $bre;
}

sub new_config {
  my $obj = shift;
  my $dfwfw_conf = shift;
  $obj->{"_dfwfw_conf"} = $dfwfw_conf;
}

sub mylog {
  my $obj = shift;
  my $msg = shift;

  $obj->{'_logger'}->($msg);
}


sub fetch_docker_configuration {
  my $obj = shift;

  $obj->mylog("Talking to Docker daemon to learn current network and container configuration");

  my $dfwfw_conf = $obj->{"_dfwfw_conf"};

  my $extra_info_needed = 
    (
     (($dfwfw_conf->{'container_internals'}->{'rules'})&&(scalar @{$dfwfw_conf->{'container_internals'}->{'rules'}})) 
     ||
     (($dfwfw_conf->{'container_aliases'}->{'rules'})&&(scalar @{$dfwfw_conf->{'container_aliases'}->{'rules'}})) 
    ) 
    ?
    1 : 0;

  $obj->{'_docker_info'} = new WebService::Docker::Info($dfwfw_conf->{'docker_socket'}, $extra_info_needed);

}

sub init_user_rules {
  my $obj = shift;
  $obj->_commit_category('initialization');
}

sub build_container_aliases {
  my $obj = shift;
  $obj->_commit_category('container_aliases');
}

sub _commit_category {
  my $obj = shift;
  my $category = shift;

  my $iptables = $obj->{'_iptables'};
  my $dfwfw_conf = $obj->{'_dfwfw_conf'};
  my $docker_info = $obj->{'_docker_info'};

  $dfwfw_conf->{$category}->commit($docker_info, $iptables);
}


sub rebuild {
  my $obj = shift;

  # this sub is called usually in context of LWP which hides the default exception outputs, so we workaround it here:
  eval {
    $obj->build_firewall_ruleset();
    $obj->build_container_aliases();
  };
  if($@) {
     $obj->mylog($@);
     die($@);
  }
}


sub build_firewall_ruleset {
  my $obj = shift;

  my $dfwfw_conf = $obj->{'_dfwfw_conf'};
  my $docker_info = $obj->{'_docker_info'};
  my $iptables = $obj->{'_iptables'};

  $obj->mylog("Rebuilding firewall ruleset...");

  my %rules;

  $rules{'filter'}  = DFWFW::Iptables->dfwfw_rules_head("DFWFW_FORWARD", 1);
  $rules{'filter'} .= DFWFW::Iptables->dfwfw_rules_head("DFWFW_INPUT");

  $rules{'nat'}     = DFWFW::Iptables->dfwfw_rules_head("DFWFW_PREROUTING");

  $dfwfw_conf->{'container_dnat'}->build($docker_info, \%rules);
  $dfwfw_conf->{'container_to_container'}->build($docker_info, \%rules);
  $dfwfw_conf->{'container_to_wider_world'}->build($docker_info, \%rules);
  $dfwfw_conf->{'container_to_host'}->build($docker_info, \%rules);
  $dfwfw_conf->{'wider_world_to_container'}->build($docker_info, \%rules);

  # and the final rule just for sure.
  $rules{'filter'} .= DFWFW::Iptables->dfwfw_rules_tail("DFWFW_FORWARD");

  if($iptables->commit_rules(\%rules)) {
    $obj->mylog("ERROR: iptables-restore returned failure");
  }

  $dfwfw_conf->{'container_internals'}->commit($docker_info, $iptables);

}





sub init_dfwfw_rules {
  my $obj = shift;

  my $iptables = $obj->{'_iptables'};
  my $dfwfw_conf = $obj->{'_dfwfw_conf'};

   if (!DFWFW::Iptables->table_already_initiated("DFWFW_FORWARD")) {
     $obj->mylog("DFWFW_FORWARD chain not found, initializing");

     $iptables->commit_rules_table("filter", <<'EOF');
:DFWFW_FORWARD - [0:0]
-I FORWARD -j DFWFW_FORWARD
EOF
   }

   if (!DFWFW::Iptables->table_already_initiated("DFWFW_INPUT")) {
     $obj->mylog("DFWFW_INPUT chain not found, initializing");

     $iptables->commit_rules_table("filter", <<'EOF');
:DFWFW_INPUT - [0:0]
-I INPUT -j DFWFW_INPUT
EOF
   }


   if (!DFWFW::Iptables->table_already_initiated("DFWFW_POSTROUTING", "nat")) {
     $obj->mylog("DFWFW_POSTROUTING chain not found, initializing");

     my $ext_interface = $dfwfw_conf->first_external_network_interface();
     $iptables->commit_rules_table("nat", <<"EOF");
:DFWFW_POSTROUTING - [0:0]
-I POSTROUTING -j DFWFW_POSTROUTING
-F DFWFW_POSTROUTING
-I DFWFW_POSTROUTING -o $ext_interface -j MASQUERADE
EOF

   }


   if (!DFWFW::Iptables->table_already_initiated("DFWFW_PREROUTING", "nat")) {
     $obj->mylog("DFWFW_PREROUTING chain not found, initializing");

     $iptables->commit_rules_table("nat", <<"EOF");
:DFWFW_PREROUTING - [0:0]
-I PREROUTING -j DFWFW_PREROUTING
EOF

   }


}


1;
