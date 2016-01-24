package DFWFW::RuleSet::Generic;

use parent "DFWFW::RuleSet::BaseParser";

use Data::Dumper;
use DFWFW::Config;

sub _get_default_policy {
  die "Abstract, not implemented";
}

sub _default_policy {
  my $ruleset = shift;
  my $cat = shift;
  my $force_default = $ruleset->_get_default_policy();

  return if(($force_default)&&($force_default eq "-"));

  $ruleset->{'dfwfw_conf'}->{$cat}->{'default_policy'} = $force_default if(($force_default)&&(!$ruleset->{'dfwfw_conf'}->{$cat}->{'default_policy'}));

  if($ruleset->{'dfwfw_conf'}->{$cat}->{'default_policy'}) {
     eval {
        DFWFW::Config->action_test($ruleset->{'dfwfw_conf'}->{$cat}, 'default_policy');
        push @{$ruleset->{'dfwfw_conf'}->{$cat}->{'rules'}}, {
           "network"=> "Name =~ .*",
           "action"=> $ruleset->{'dfwfw_conf'}->{$cat}->{'default_policy'},
        } if(($ruleset->{'dfwfw_conf'}->{$cat}->{'default_policy'} ne "DROP")||($cat eq "container_to_host"));
     };
     if($@) {
        die "ERROR: invalid default policy for $cat: $@";
     }
  }

}


sub parse {
  my $ruleset = shift;
  my $category = shift;

  ### parsing category: $category

  $ruleset->_default_policy($category);

  $ruleset->SUPER::parse($category);
}

sub build {
  
  my $ruleset = shift;
  my $docker_info = shift;
  my $re = shift;

  my %sre;
  $ruleset->SUPER::build($docker_info, \%sre);

  my $category = $ruleset->_get_category();
  for my $k (keys %sre) {
     $re->{$k} .= "################ $category:\n$sre{$k}\n\n"  if($sre{$k});
  }
}


1;
