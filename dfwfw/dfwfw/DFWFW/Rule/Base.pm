package DFWFW::Rule::Base;

use Data::Dumper;

sub new {
  my $class = shift;
  my $ruleset = shift;
  my $node = shift;

  my $re = {
     "ruleset" => $ruleset,
     "node" => $node
  };

  return bless $re, $class;
}

sub validate_keys {
  my $class = shift;
  my $node = shift;
  my @keys = @_;

   for my $k (keys %$node) {
          die "Invalid key: $k" if(!($k ~~ @keys));
   }

}

sub info {
  my $rule = shift;

  return Dumper($rule->{'node'});
}

sub build {
  die "Abstract, not implemented";
}

sub parse {
  die "Abstract, not implemented";
}

sub get_dfwfw_conf {
  my $self = shift;
  return $self->{'ruleset'}->{'dfwfw_conf'};
}

sub mylog {
  my $rule = shift;
  my $msg = shift;

  $rule->{'ruleset'}->mylog($msg);
}

1;
