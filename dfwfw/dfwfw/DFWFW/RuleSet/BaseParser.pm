package DFWFW::RuleSet::BaseParser;

use parent "DFWFW::RuleSet::Base";

use Data::Dumper;
use DFWFW::Config;

use DFWFW::Rule::ContainerToContainer;
use DFWFW::Rule::ContainerToWiderWorld;
use DFWFW::Rule::ContainerToHost;
use DFWFW::Rule::WiderWorldToContainer;
use DFWFW::Rule::ContainerDnat;
use DFWFW::Rule::ContainerInternal;
use DFWFW::Rule::ContainerAlias;

sub _get_rule_class { 
  my $obj = shift;

  my $cname = ref($obj);
  die "Invalid classname: $cname" if($cname !~ /^DFWFW::RuleSet::(.+)/);
  return "DFWFW::Rule::$1";
}

sub _get_category {
  my $ruleset = shift;

  return $ruleset->{'_category'};
}



sub parse {
  my $ruleset = shift;
  my $category = shift;

  $ruleset->{'_category'} = $category;

  my $class = $ruleset->_get_rule_class();

  ### category: $category

  my $dfwfw_conf = $ruleset->{'dfwfw_conf'};

  return if(!$dfwfw_conf->{$category}->{'rules'});

  return if(!scalar @{$dfwfw_conf->{$category}->{'rules'}});


     my $rno = 0;
     for my $node (@{$dfwfw_conf->{$category}->{'rules'}}) {

        eval {
           my $c = $class->new($ruleset, $node);
           $c->parse($node);
           $node = $c; # success.
        };
        $node->{'node'}->{'no'} = ++$rno;


        if($@) {
           die "ERROR: $@ in:\n".Dumper($node);
        }

     }

  $ruleset->{'rules'} = $dfwfw_conf->{$category}->{'rules'};

}

sub info {
  my $ruleset = shift;

  my $category = $ruleset->_get_category();

  my $re = "";
  for my $rule (@{$ruleset->{'dfwfw_conf'}->{$category}->{'rules'}}) {
     $re .= $rule->info();
  }
  return $re;
}

sub build {
  
  my $ruleset = shift;
  my $docker_info = shift;
  my $re = shift;

  my $category = $ruleset->_get_category();

  if($ruleset->{'dfwfw_conf'}->{$category}->{'rules'})
  {

    for my $rule (@{$ruleset->{'dfwfw_conf'}->{$category}->{'rules'}}) {

         $rule->build($docker_info, $re);

    }

  }

}



1;
