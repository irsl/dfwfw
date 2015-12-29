package DFWFW::Rule::GenericNetwork;

use parent "DFWFW::Rule::Generic";

use Data::Dumper;

sub _parse {
  my $rule = shift;
  my $node = shift;
  my @extra_keys = @_;

  die "No network specified" if(!$node->{"network"});

  $rule->SUPER::_parse($node, "network", @extra_keys);
}

sub _build_network {
  my $rule = shift;
  my $docker_info = shift;
  my $re = shift;
  my $network = shift;

  die "Abstract, not implemented";

}

sub build {
  my $self = shift;
  my $docker_info = shift;
  my $re = shift;

  $rule = $self->{'node'};
  my $category = ref($self);

  my $matching_nets = DFWFW::Filters->filter_networks_by_ref($docker_info, $rule->{'network-ref'});
  $self->mylog("$category: number of matching networks for rule #$rule->{'no'}: ".(scalar @$matching_nets));

  ### Matching nets: Dumper($matching_nets)

  for my $net (@$matching_nets) {
     $self->_build_network($docker_info, $re, $net);
  }

}


1;
