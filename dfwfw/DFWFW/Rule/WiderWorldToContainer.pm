package DFWFW::Rule::WiderWorldToContainer;

use parent "DFWFW::Rule::GenericNetwork";

use DFWFW::Filters;

sub _build_network_container_expose {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;
  my $network = shift;

  my $d = shift;
  my $expose = shift;

  my $rule = $self->{'node'};
  my $dfwfw_conf = $self->get_dfwfw_conf();


  my $cname = $docker_info->{'container_by_ip'}->{$d}->{'Name'};

   for my $ep (@$expose) {
       my $cmnt = "# #$rule->{'no'}: host:$ep->{'host_port'} -> $cname:$ep->{'container_port'} / $ep->{'family'}\n";
       $re->{'nat'} .= $cmnt;
       my $cportstr = ($ep->{'container_port'} ? ":$ep->{'container_port'}" : "");
       $re->{'nat'} .= "-A DFWFW_PREROUTING -i $dfwfw_conf->{'external_network_interface'} -p $ep->{'family'} --dport $ep->{'host_port'} $rule->{'filter'} -j DNAT --to-destination $d$cportstr\n";

       $re->{'filter'} .= $cmnt;
       my $cport = ($ep->{'container_port'} ? $ep->{'container_port'} : $ep->{'host_port'});
       $re->{'filter'} .= "-A DFWFW_FORWARD -i $dfwfw_conf->{'external_network_interface'} -o $network->{'BridgeName'} -d $d -p $ep->{'family'} --dport $cport -j ACCEPT\n";
   }

}



sub _build_network {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;
  my $network = shift;

  my $rule = $self->{'node'};


  ### ww2c rule network: $rule->{'no'}

  if(!$rule->{'dst_container-ref'}) {
      $self->mylog("Wider world to container: dst_container not specified in rule #$rule->{'no'}, skipping rule");
      return;
  }

  my $dst = DFWFW::Filters->filter_hash_by_ref($rule->{'dst_container-ref'}, $network->{'ContainerList'});
  if(!scalar @$dst) {
    $self->mylog("Wider world to container: dst_container of rule #$rule->{'no'} does not match any containers, skipping rule");
    return ;
  }


  for my $d (@$dst) {

     my $expose = $rule->{'expose_port'} || $docker_info->get_expose_ports($d);

     $self->_build_network_container_expose($docker_info, $re, $network, $d, $expose);
  }


}

sub parse {
  my $rule = shift;
  my $node = shift;

  $rule->_parse($node, "expose_port","dst_container");
}

1;
