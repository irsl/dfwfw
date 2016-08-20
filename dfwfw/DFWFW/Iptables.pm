package DFWFW::Iptables;

use strict;
use warnings;
use File::Slurp;
use experimental 'smartmatch';
use constant IPTABLES_TABLES => ["filter","raw","nat","mangle","security"];
use constant IPTABLES_TMP_FILE => "/tmp/dfwfw";


sub table_already_initiated {
   my $class = shift;
   my $chain = shift;
   my $table = shift || "filter";
   return 0 == system("iptables -n -t $table --list $chain >/dev/null 2>&1");
}

sub dfwfw_rules_head {
  my $class = shift;

  my $cat = shift;
  my $stateful = shift;

  my $re = "################ $cat head:
-F $cat
";
$re.= "-A $cat -m state --state INVALID -j DROP
-A $cat -m state --state RELATED,ESTABLISHED -j ACCEPT
" if($stateful);

  $re .= "\n";

  return $re;
}

sub dfwfw_rules_tail {
  my $class = shift;

  my $cat = shift;
  return "" if($cat eq "DFWFW_INPUT"); # exception

  return "################ $cat tail:
-A $cat -j DROP

";
}



sub validate_table {
  my $class = shift;
  my $table = shift;

  die "Invalid table: $table" if(!($table ~~ IPTABLES_TABLES));
}

sub new {
  my $class = shift;
  my $logger = shift;
  my $c_dry_run = shift;
  die "No logger" if(!$logger);
  my $obj = bless {"_logger"=>$logger, "_dry_run"=>$c_dry_run}, $class;
  return $obj;
}

sub build_and_commit_rulesets {
  my ($obj, $rulesets, $pid_for_nsenter) = @_;

  my %re;
  for my $ruleset (@$rulesets) {
     $ruleset->build(\%re);
  }

  return $obj->commit_rules(\%re, $pid_for_nsenter);
}

sub commit_rules {
  my ($obj, $rules_hash, $pid_for_nsenter) = @_;

  my $rc = 0;
  # we sort the keys here so unit tests can be deterministic
  for my $table (sort keys %$rules_hash) {
     $rc += $obj->commit_rules_table($table, $rules_hash->{$table}, $pid_for_nsenter);
  }
  return $rc;
}

sub commit_rules_table {
  my ($obj, $table, $rules, $pid_for_nsenter) = @_;

  my $complete = "
*$table
$rules
COMMIT
";
  $complete =~ s/ {2,}/ /g;

  $obj->{'_logger'}->(($obj->{'_dry_run'} ? "Dry-run, not " : ""). "commiting to $table table".($pid_for_nsenter?" via nsenter for pid $pid_for_nsenter":"").":\n$complete\n");

  my $iptables_errors;
  if(!$obj->{'_dry_run'}) {
     write_file(IPTABLES_TMP_FILE, $complete);

     my $cmd_prefix = $pid_for_nsenter ? "nsenter -t $pid_for_nsenter -n" : "";
     my $cmd = "$cmd_prefix iptables-restore -c --noflush ".IPTABLES_TMP_FILE." 2>&1";
     $iptables_errors = `$cmd`;
     $obj->{'_logger'}->("ERROR: $iptables_errors") if($iptables_errors);

     unlink(IPTABLES_TMP_FILE);
  }
  return $iptables_errors ? 1 : 0;
}


1;
