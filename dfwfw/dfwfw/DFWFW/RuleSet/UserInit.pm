package DFWFW::RuleSet::UserInit;

use parent "DFWFW::RuleSet::Base";

use DFWFW::Iptables;
use Data::Dumper;

sub parse {
  my $ruleset = shift;
  my $key = shift;

  return if(!$ruleset->{'dfwfw_conf'}->{$key});


  for my $table (keys %{$ruleset->{'dfwfw_conf'}->{$key}}) {
      DFWFW::Iptables->validate_table($table);

      $ruleset->{'_rules'}->{$table} = $ruleset->{'dfwfw_conf'}->{$key}->{$table};
  }

}

sub info {
  my $ruleset = shift;
  return Dumper($ruleset->{'_rules'});
}

sub build {
  my $ruleset = shift;
  my $docker_info = shift;
  my $re = shift;

  return if(!$ruleset->{'_rules'});

  for my $table (keys %{$ruleset->{'_rules'}}) {

      my $rules = "";
      for my $l (@{$dfwfw_conf->{'initialization'}->{$table}}) {
         $rules .= "$l\n";
      }
      $re->{$table} = $rules;
  }

}


1;
