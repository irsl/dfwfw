package DFWFW::Rule::ContainerDnat;

use parent "DFWFW::Rule::Generic";

use DFWFW::Filters;


sub _build_dst_src {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;

  my $d = shift;
  my $dst_network = shift;
  my $expose = shift;

  my $src_network = shift;
  my $srcs = shift;

  my $rule = $self->{'node'};
  my $dfwfw_conf = $self->get_dfwfw_conf();

     my $cname = $docker_info->{'container_by_ip'}->{$d}->{'Name'};
     for my $s (@$srcs) {

       for my $ep (@$expose) {
         my $src_network_str = "";
         $src_network_str = "-i $src_network->{'BridgeName'}" if($src_network);
         $src_network_str = "! -i $dfwfw_conf->{'external_network_interface'}" if(!$src_network);
         my $dst_network_str = "";
         $dst_network_str = "-o $dst_network->{'BridgeName'}" if($dst_network);

         my $cmnt = "# #$rule->{'no'}: $s:$ep->{'host_port'} @ $src_network_str -> $cname:$ep->{'container_port'} @ $dst_network_str / $ep->{'family'}\n";

         my $sstr = "";
         $sstr = "-s $s" if($s);

         $re->{'nat'} .= $cmnt;
         $re->{'nat'} .= "-A DFWFW_PREROUTING $src_network_str -p $ep->{'family'} --dport $ep->{'host_port'} $rule->{'filter'} -j DNAT --to-destination $d:$ep->{'container_port'}\n";

         $re->{'filter'} .= $cmnt;
         $re->{'filter'} .= "-A DFWFW_FORWARD $src_network_str $dst_network_str $sstr -d $d -p $ep->{'family'} --dport $ep->{'container_port'} -j ACCEPT\n";
       }
     }

}


sub _build_dst {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;

  my $d = shift;
  my $dst_network = shift;
  my $expose = shift;

  my $rule = $self->{'node'};

  my $src = [""];
  my $matching_nets = [""];
  if($rule->{'src_container-ref'}) {
     $matching_nets = DFWFW::Filters->filter_networks_by_ref($docker_info, $rule->{'src_network-ref'});
     $self->mylog("Container dnat: number of matching src networks for rule #$rule->{'no'}: ".(scalar @$matching_nets));

  }

  my $src_containers = 0;
  for my $src_network (@$matching_nets) {
     my $srcs = [""];
     $srcs = DFWFW::Filters->filter_hash_by_ref($rule->{'src_container-ref'}, $src_network->{'ContainerList'}) if($src_network);

     my $c_srcs = scalar @$srcs;
     if(!$c_srcs) {
         $self->mylog("Container dnat: src_container in network $src_network of rule #$rule->{'no'} does not match any containers, skipping network");
         next;
     }


     $self->_build_dst_src($docker_info, $re, $d, $dst_network, $expose, $src_network, $srcs);

     $src_containers+= $c_srcs;
  }

  if(!$src_containers) {
     $self->mylog("Container dnat: src_containers of rule #$rule->{'no'} does not match any containers, skipping rule");
  }

}


sub build {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;

  my $rule = $self->{'node'};

  ### cdnat rule network: $rule->{'no'}

  if(!$rule->{'dst_container-ref'}) {
      $self->mylog("Container dnat: dst_container not specified in rule #$rule->{'no'}, skipping rule");
      return;
  }


  my $matching_nets = DFWFW::Filters->filter_networks_by_ref($docker_info, $rule->{'dst_network-ref'});
  if(!scalar @$matching_nets) {
     $self->mylog("Container dnat: dst_network of rule #$rule->{'no'} does not match any networks, skipping rule");
     return ;
  }

  $self->mylog("Container dnat: number of matching dst networks for rule #$rule->{'no'}: ".(scalar @$matching_nets));

  my %dst_ip_to_network_name_map;
  my @hsrc;
  for my $network (@$matching_nets) {
     my $adsts = DFWFW::Filters->filter_hash_by_ref($rule->{'dst_container-ref'}, $network->{'ContainerList'});
     for my $d (@$adsts) {
        $dst_ip_to_network_name_map{$d} = $network;
     }
     push @hsrc, @$adsts;

  }

  if(!scalar @hsrc) {
     $self->mylog("Container dnat: dst_container of rule #$rule->{'no'} does not match any containers, skipping rule");
     return ;
  }



  my $dst = \@hsrc;
  for my $d (@$dst) {

     my $expose = $rule->{'expose_port'} || $docker_info->get_expose_ports($d);

     $self->_build_dst($docker_info, $re, $d, $dst_ip_to_network_name_map{$d}, $expose);
  }



}

sub _parse {

  my $rule = shift;
  my $node = shift;

  my @extra_keys = @_;

   die "You must specify both src_network and src_container" if( (($node->{'src_container'})&&(!$node->{'src_network'})) || ((!$node->{'src_container'})&&($node->{'src_network'})));

   die "Destination network is not defined" if(!$node->{'dst_network'});
   die "Destination container is not defined" if(!$node->{'dst_container'});
   die "Expose port is not defined" if(!$node->{'expose_port'});

  $rule->SUPER::_parse($node, @extra_keys);
}

sub parse {
  my $rule = shift;
  my $node = shift;

  $rule->_parse($node, "src_network", "src_container", "expose_port", "dst_container", "dst_network");
}

1;
