package DFWFW::Rule::GenericNetworkInterface;

use parent "DFWFW::Rule::GenericNetwork";

use Data::Dumper;

sub _parse {
  my $rule = shift;
  my $node = shift;
  my @extra_keys = @_;


  $rule->SUPER::_parse($node, "external_network_interface", @extra_keys);

}



1;
