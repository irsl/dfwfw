package DFWFW::Rule::ContainerToContainer;

use parent "DFWFW::Rule::GenericNetwork";

use DFWFW::Filters;
use Data::Dumper;

sub _build_network_src_dst {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;
  my $network = shift;

  my $s = shift;
  my $d = shift;


  my $rule = $self->{'node'};

  my $sstr = ($s ? "-s $s" : "");
  my $sstrcomment = ($s ? "from:".$docker_info->{'container_by_ip'}->{$s}->{'Name'} : "");
  my $dstr = ($d ? "-d $d" : "");
  my $dstrcomment = ($d ? "to:".$docker_info->{'container_by_ip'}->{$d}->{'Name'} : "");

  if(($sstrcomment)||($dstrcomment)) {
     $re->{'filter'} .= "# #$rule->{'no'}: $sstrcomment $dstrcomment\n";
  }
  $re->{'filter'} .= "-A DFWFW_FORWARD -i $network->{'BridgeName'} -o $network->{'BridgeName'} $sstr $dstr $rule->{'filter'} -j $rule->{'action'}\n";

}

sub _build_network {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;
  my $network = shift;

  my $rule = $self->{'node'};


  ### c2c rule network: $rule->{'no'}

  if(!$rule->{'src_dst_container'}) {
    my $src = [""];
    if($rule->{'src_container-ref'}) {
      $src = DFWFW::Filters->filter_hash_by_ref($rule->{'src_container-ref'}, $network->{'ContainerList'});
      if(!scalar @$src) {
         $self->mylog("Container to container: src_container of rule #$rule->{'no'} does not match any containers, skipping rule");
         return ;
      }

    }

    my $dst = [""];
    if($rule->{'dst_container-ref'}) {
       $dst = DFWFW::Filters->filter_hash_by_ref($rule->{'dst_container-ref'}, $network->{'ContainerList'});
       if(!scalar @$dst) {
          $self->mylog("Container to container: dst_container of rule #$rule->{'no'} does not match any containers, skipping rule");
          return ;
       }
    }

    for my $s (@$src) {
       for my $d (@$dst) {
         $self->_build_network_src_dst($docker_info, $re, $network, $s, $d);

       }
    }

  } else {
      my $src_dst_pairs = DFWFW::Filters->filter_hash_by_sd_ref($rule->{'src_dst_container-ref'}, $network->{'ContainerList'});
      #print Dumper($src_dst_pairs);exit;
      if(!scalar @$src_dst_pairs) {
         $self->mylog("Container to container: src_dst_container of rule #$rule->{'no'} does not match any containers, skipping rule");
         return ;
      }
      for my $pair (@$src_dst_pairs) {
          $self->_build_network_src_dst( $docker_info, $re, $network, $pair->{'src'}, $pair->{'dst'});
      }

  }

}



sub parse {
  my $rule = shift;
  my $node = shift;

  $rule->_parse($node, "action","src_container", "dst_container", "src_dst_container");
}

1;
