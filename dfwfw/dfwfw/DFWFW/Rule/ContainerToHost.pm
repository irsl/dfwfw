package DFWFW::Rule::ContainerToHost;

use parent "DFWFW::Rule::GenericNetwork";

use DFWFW::Filters;

sub _build_network {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;
  my $network = shift;

  my $rule = $self->{'node'};


  ### c2h rule network: $rule->{'no'}

  my $src = [""];
  if($rule->{'src_container-ref'}) {
     $src = DFWFW::Filters->filter_hash_by_ref($rule->{'src_container-ref'}, $network->{'ContainerList'});
     if(!scalar @$src) {
        $self->mylog("Container to host: src_container of rule #$rule->{'no'} does not match any containers, skipping rule");
        return ;
     }

  }

  for my $s (@$src) {
         my $sstr = ($s ? "-s $s" : "");
         my $sstrcomment = ($s ? "from:".$docker_info->{'container_by_ip'}->{$s}->{'Name'} : "");

         if($sstrcomment) {
            $re->{'filter'} .= "# #$rule->{'no'}: $sstrcomment\n";
         }
         $re->{'filter'} .= "-A DFWFW_INPUT -i $network->{'BridgeName'} $sstr $rule->{'filter'} -j $rule->{'action'}\n";
  }

}

sub parse {
  my $rule = shift;
  my $node = shift;

  $rule->_parse($node, "action","src_container");
}

1;
