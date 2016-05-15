package DFWFW::RuleSet::ContainerAlias;

use parent "DFWFW::RuleSet::BaseParser";


sub commit {
  my $ruleset = shift;
  my $docker_info = shift;
  my $iptables = shift;

  my %host_files;
  $ruleset->build($docker_info, \%host_files);
#  print Dumper(\%rules_to_commit);exit;

  if(!$iptables->{'_dry_run'}) {
    for my $hf (keys %host_files) {
        $ruleset->mylog("Flushing hosts file: ".$hf);
        $host_files{$hf}->flush();
    }

  } else {
    $ruleset->mylog("Not flushing hosts file in dry mode");
  }
}

1;
