package DFWFW::RuleSet::ContainerToHost;

use parent "DFWFW::RuleSet::Generic";

sub _get_default_policy {
  return "DROP";
}

1;
