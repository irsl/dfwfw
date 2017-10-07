#!/usr/bin/perl

use strict;
use warnings;
use Test::MockModule;
use Test::More;
use FindBin qw($Bin);
use File::Slurp;
use Data::Dumper;
use experimental "smartmatch";
use constant COMMIT_SEPARATOR => "##--SEPARATOR--##";
BEGIN {
  push @INC, "$Bin/..", "$Bin/../ConfigHostsFile/lib", "$Bin/../PreJSONParser/lib", "$Bin/../WebServiceDocker/lib";
};
use Config::HostsFile;
use DFWFW::Config;
use DFWFW::Iptables;
use DFWFW::Fire;

opendir(my $d, $Bin) or die "cant open: $!";
my @tests = grep { ((/^\d+/) && (-d "$Bin/$_"))} readdir($d);
closedir($d);


for my $test (@tests) {
  next if ((scalar @ARGV) && (!($test ~~ \@ARGV)));

  my $fulldir = "$Bin/$test";

  my $docker_defs = require "$fulldir/docker_definitions.pl";
  my $description = cleanup("$test: ". read_file("$fulldir/description.txt"));
  my @commits = parse_expected_commits("$fulldir/commits.txt");
  #print Dumper(\@commits);exit;
  my $existing_chains = read_existing_chains("$fulldir/chains.txt");
  ### existing_chains: $existing_chains

  my $api_module = Test::MockModule->new('WebService::Docker::API');
  $api_module->mock('networks',   sub { return $docker_defs->{'mocked_networks_response'}; });
  $api_module->mock('containers', sub { return $docker_defs->{'mocked_containers_response'}; });
  $api_module->mock('container_info', sub {
     my ($obj, $id) = @_;

     die "DFWFW tried to query an unexpected container info" if(!defined($docker_defs->{'mocked_container_infos'}->{$id}));

     return $docker_defs->{'mocked_container_infos'}->{$id}; 
  });


  my $info_module = Test::MockModule->new('WebService::Docker::Info');
  $info_module->mock('get_hosts_file_by_container_name', sub {
      my $this = shift;
      my $ctname = shift;

      return hosts_file_path($fulldir,$ctname,"before");
  });

  my $iptables_module = Test::MockModule->new('DFWFW::Iptables');
  $iptables_module->mock('table_already_initiated', sub {
    my $class = shift;
    my $chain = shift;
    my $table = shift || "filter";

    ### Checking if table was already initiated: $table - $chain
    return "$table $chain" ~~ $existing_chains;
  });

  my $commit_counter = 0;
  $iptables_module->mock('commit_rules_table', sub {
     my ($obj, $table, $rules, $pid_for_nsenter) = @_;
     $pid_for_nsenter ||= "";

     $commit_counter++;
     commitlog("#Table: $table");
     commitlog("#nsenter_pid: $pid_for_nsenter");
     commitlog($rules);
     commitlog(COMMIT_SEPARATOR);

     my $expected_commit = shift @commits;
     ok($expected_commit, "Unexpected commit at $description");
     return 1 if(!$expected_commit);
     #print Dumper($expected_commit);

     is($table, $expected_commit->{'table'}, "Mismatching table at $commit_counter/$description");
     is($pid_for_nsenter, $expected_commit->{'nsenter_pid'}, "Mismatching pid for nsenter at $description");
     is(cleanup($rules), cleanup($expected_commit->{'rules'}), "Mismatching rules at $commit_counter/$description");

     return 0;
  });

  my $alias_module = Test::MockModule->new('DFWFW::RuleSet::ContainerAlias');
  $alias_module->mock('commit', sub {
     my $ruleset = shift;
     my $docker_info = shift;
     my $iptables = shift;

     my %host_files;
     $ruleset->build($docker_info, \%host_files);

     for my $ctname (keys %host_files) {

        my $expectedfile = hosts_file_path($fulldir,$ctname,"after");
        my $expected = read_file($expectedfile);
        $expected = cleanup($expected);

        my $got = cleanup($host_files{$ctname}->render());

        is($got, $expected, "$ctname hosts file was not modified as expected at $description");
     }
  });

  my $dfwfw_conf = DFWFW::Config->new(\&mylog, "$fulldir/dfwfw.conf");
  my $iptables = DFWFW::Iptables->new(\&mylog, 1);
  my $fire = DFWFW::Fire->new(\&mylog, $iptables);
  $fire->new_config($dfwfw_conf);

  $fire->init_dfwfw_rules();

  $fire->fetch_docker_configuration();
  $fire->init_user_rules();

  $fire->rebuild();

  # and now lets see if we expected any more commits
  ok(0 == scalar @commits, "Expected more commits at $description");
}

done_testing();

sub commitlog {
  my $msg = shift;
  print STDERR "$msg\n" if($ENV{"COMMITLOG"});
}

sub mylog {
  my $msg = shift;
  print STDERR "$msg\n" if($ENV{"VERBOSE"});
}

sub cleanup {
  my $text = shift || "";
  $text =~ s/^#.+//gm;
  $text =~ s/\n{2,}/\n/g;
  $text =~ s/^\s*//g;
  $text =~ s/\s*$//g;
  $text =~ s/\s{2,}/ /g;
  return $text;
}

sub parse_expected_commits {
  my $fn = shift;
  my $text = read_file($fn);
  my @commit_blocks = split(/${\(COMMIT_SEPARATOR)}\n/, $text);
  my @re;
  for my $block (@commit_blocks) {
     die "invalid block:\n$block" if($block !~ /^#Table: (\w+)\n#nsenter_pid:\s*(\d+)?\n(.+)/s);
     my %b;
     $b{"table"} = $1;
     $b{"nsenter_pid"} = $2 || "";
     $b{"rules"} = $3;
     push @re, \%b;
  }

  return @re;
}

sub read_existing_chains{
  my $fn = shift;
  open (my $f, "<$fn") or return [];
  my @re = map { /^(.+)$/ && $1 } grep { !/^#/ && !/^$/ } <$f>;
  close($f);
  return \@re;
}

sub hosts_file_path {
  my ($dir, $ctname, $type) = @_;
  return "$dir/hosts-$ctname.$type";
}


=standalone mode
sub is {
  my $got = shift;
  my $expected = shift;
  my $d = shift;
  eval {
    ok($got eq $expected, $d);
  };
  if($@) {
    print STDERR "GOT:\n$got\n\n";
    print STDERR "EXPECTED:\n$expected\n\n";
    die $@;
  }
}
sub ok {
  my $v = shift;
  my $d = shift;
  die $d if((!$v)&&(!$ENV{"SUPERHERO"}));
}
sub done_testing {
  print STDERR "Clean exit\n";
}
=cut
