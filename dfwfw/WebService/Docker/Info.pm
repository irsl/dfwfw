package WebService::Docker::Info;

use warnings;
use strict;
use LWP::UserAgent;
use URI;
use JSON::XS;
use WebService::Docker::Info;

sub new {
  my $class = shift;
  my $docker_socket = shift;
  my $query_extra_info = shift || 0;

  my $re;
  for my $k ("container_by_ip","container_by_id","container_by_name","container_extra_by_name",
     "network_by_name","network_by_id","network_by_bridge") {
     $re->{$k} = {};
  }


  my $api = WebService::Docker::API->new($docker_socket);
  my $networks = $api->networks();
  my $containers = $api->containers();

  for my $cont (@$containers) {

     $cont->{'IdShort'} = substr($cont->{'Id'}, 0, 12);

     $re->{'container_by_id'}->{$cont->{'Id'}} = $cont;
     for my $name (@{$cont->{'Names'}}) {
        $name =~ s#^/*##;
        $re->{'container_by_name'}->{$name} = $cont;
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
        my $cont = $re->{'container_by_id'}->{$cid};

        my $ipv4 =  $net->{'Containers'}->{$cid}->{'IPv4Address'};
        $ipv4 =~ s#^(.+)/\d+$#$1#;

        $net->{'ContainerList'}->{$ipv4} = $cont;
        $cont->{'NetworkList'}->{$ipv4} = $net;

        $re->{'container_by_ip'}->{$ipv4} = $cont;
     }

     $re->{'network_by_name'}->{$net->{'Name'}} = $net;
     $re->{'network_by_id'}->{$net->{'Id'}} = $net;
     $re->{'network_by_bridge'}->{$net->{'BridgeName'}} = $net;
  }

  if($query_extra_info)
  {
     for my $name (keys %{$re->{'container_by_name'}}) {
        my $c = $re->{'container_by_name'}->{$name};
        my $full_info = $api->container_info($c->{'Id'});
        $re->{'container_extra_by_name'}->{$name} = $full_info;
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


  return bless $re, $class;

}

sub get_hosts_file_by_container_name {
  my $this = shift;
  my $ctname = shift;

  return $this->{'container_extra_by_name'}->{$ctname}->{'HostsPath'};
}

sub get_pid_by_container_name {
  my $this = shift;
  my $ctname = shift;

  return $this->{'container_extra_by_name'}->{$ctname}->{'State'}->{'Pid'};
}

sub get_expose_ports {
  my ($docker_info, $ip_of_container) = @_;

        my @e;
        ### building exposed ports based on the current docker configuration
        for my $port (@{$docker_info->{'container_by_ip'}->{$ip_of_container}->{'Ports'}}) {
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
        return \@e;

}

1;
