package DFWFW::Iptables;

use strict;
use warnings;
use File::Slurp;
use experimental 'smartmatch';
use constant IPTABLES_TABLES => ["filter","raw","nat","mangle","security"];
use constant IPTABLES_TMP_FILE => "/tmp/dfwfw";


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

sub commit {
  my ($obj, $table, $rules, $pid_for_nsenter) = @_;

  my $complete = "
*$table
$rules
COMMIT
";
  $complete =~ s/ {2,}/ /g;

  $obj->{'_logger'}->(($obj->{'_dry_run'} ? "Dry-run, not " : ""). "commiting to $table table".($pid_for_nsenter?" via nsenter for pid $pid_for_nsenter":"").":\n$complete\n");


  if(!$obj->{'_dry_run'}) {
     write_file(IPTABLES_TMP_FILE, $complete);

     my $cmd_prefix = $pid_for_nsenter ? "nsenter -t $pid_for_nsenter -n" : "";
     system("$cmd_prefix iptables-restore -c --noflush ".IPTABLES_TMP_FILE);

     unlink(IPTABLES_TMP_FILE);
  }
}


1;
