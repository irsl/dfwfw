package DFWFW::RuleSet::ContainerDnat;

use parent "DFWFW::RuleSet::Generic";


sub _get_default_policy {
  return "-";
}

1;
