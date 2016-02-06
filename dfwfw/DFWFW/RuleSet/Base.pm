package DFWFW::RuleSet::Base;

sub new {
  my $class = shift;
  my $dfwfw_conf = shift;

  die "dfwfw_conf not specified" if(!$dfwfw_conf);

  my $re = {
     "dfwfw_conf" => $dfwfw_conf
  };

  return bless $re, $class;
}

sub parse {
  die "Abstract, not implemented";
}

sub build {
  die "Abstract, not implemented";
}

sub info {
  die "Abstract, not implemented";
}

sub commit {
  my $ruleset = shift;
  my $docker_info = shift;
  my $iptables = shift;

  my %re;
  $ruleset->build($docker_info, \%re);
  $ruleset->mylog("ERROR: iptables-restore returned failure") if( $iptables->commit_rules(\%re) );
}

sub mylog {
  my $obj = shift;
  my $msg = shift;
  $obj->{'dfwfw_conf'}->mylog($msg);

}

sub print {
  my $obj = shift;
  $obj->mylog($obj->info());
}


1;
