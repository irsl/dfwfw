package DFWFW::Rule::ContainerAlias;

use parent "DFWFW::Rule::Base";

use DFWFW::Config;
use Data::Dumper;
use Config::HostsFile;


sub parse {
  my $rule = shift;
  my $node = shift;

  my @nodes = ("aliased_container","alias_name","receiver_network","receiver_containers");

  DFWFW::Rule::Base->validate_keys($node, @nodes);

  die "Aliased container not specified" if(!DFWFW::Config->parse_container_ref($node, "aliased_container"));
  die "Receiver containers not specified" if(!DFWFW::Config->parse_container_ref($node, "receiver_containers"));
  die "No network specified" if(!DFWFW::Config->parse_network_ref($node, "receiver_network"));

}

sub build {
  my $self = shift;
  my $docker_info = shift;
  my $host_files = shift;

  my $rule = $self->{'node'};


       my $alias_name = $rule->{'alias_name'} || "";
       $self->mylog("Alias wanted: $alias_name");

       my $cts = DFWFW::Filters->filter_hash_by_ref($rule->{'aliased_container-ref'}, $docker_info->{'container_by_name'});
       if(!scalar @$cts) {
           $self->mylog("Container aliases: rule #$rule->{'no'} does not match any aliased containers, skipping rule");
           return;
       }

       for my $ctname (@$cts) {

           $alias_name = $rule->{'alias_name'} || $ctname;

           $self->mylog ("Aliased container: $ctname");

           my $matching_nets = DFWFW::Filters->filter_networks_by_ref($docker_info, $rule->{'receiver_network-ref'});
           for my $net (@{$matching_nets}) {
               my $alias_matches = DFWFW::Filters->filter_hash_by_name($ctname, $net->{'ContainerList'});
               # print Dumper(\keys %{$net->{'ContainerList'}}); print Dumper($alias_matches);exit;
               if(scalar @$alias_matches != 1) {
                  $self->mylog("it seems the aliased container is not in this network: ".Dumper($alias_matches));
                  next;
               }
               my $alias_ip = $alias_matches->[0];

               $self->mylog ("Aliased container: $ctname ($alias_ip), receiver network: $net->{'Name'}");


               my $receiver_containers = DFWFW::Filters->filter_hash_by_ref($rule->{'receiver_containers-ref'}, $net->{'ContainerList'});
               for my $receiver_ip (@{$receiver_containers}) {
                  my $receiver = $net->{'ContainerList'}->{$receiver_ip};
                  my $receiver_name = $receiver->{'Name'};
                  $self->mylog ("Aliased container: $ctname ($alias_ip), receiver network: $net->{'Name'}, receiver container: $receiver_name ($receiver_ip)");

                  my $hosts_file =  $docker_info->get_hosts_file_by_container_name($receiver_name);
                  if(!$hosts_file) {
                        $self->mylog("Woho, we can't seem to find the hosts file of this container");
                        ### Dumper( $docker_info->{'container_extra_by_name'} );
                        next;
                  }

                  if(!defined($host_files->{$receiver_name})) {
                      $self->mylog("Opening hosts file $hosts_file for $receiver_name");
                      $host_files->{$receiver_name} = Config::HostsFile->new($hosts_file);
                  }

                  $host_files->{$receiver_name}->update_host($alias_name, $alias_ip);
               }

           }

       }


}



1;
