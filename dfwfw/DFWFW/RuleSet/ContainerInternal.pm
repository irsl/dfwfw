package DFWFW::RuleSet::ContainerInternal;

use parent "DFWFW::RuleSet::BaseParser";


sub commit {
  my $ruleset = shift;
  my $docker_info = shift;
  my $iptables = shift;

  my %rules_to_commit;
  $ruleset->build($docker_info, \%rules_to_commit);
#  print Dumper(\%rules_to_commit);exit;

  for my $ctname (keys %rules_to_commit) {
     for my $table (keys %{$rules_to_commit{$ctname}}) {
         my $rules = $rules_to_commit{$ctname}{$table};

         my $pid = $docker_info->get_pid_by_container_name($ctname);
         if($pid) {
            $ruleset->mylog("Commiting $table table rules for container $ctname via nsenter");
            $iptables->commit_rules_table($table, $rules, $pid);
         } else {
            $ruleset->mylog("Skipping container internal rule commit for $ctname, we have no pid");
         }

     }
  }

}

1;
