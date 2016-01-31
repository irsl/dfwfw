package DFWFW::Logger;

use strict;
use warnings;
use IO::Handle;
use Time::HiRes qw ( time );

sub log {
   my $obj = shift;
   my $msg = shift;

   $obj->_reopen() if(!$obj->{'_fh'});

   my $fmsg = "[".localtime."] $msg\n";

   print $fmsg; # to stdout

   $obj->{'_fh'}->print( $fmsg );
}

sub _reopen {
  my $obj = shift;
  close $obj->{'_fh'} if($obj->{'_fh'});

  my $fn = $obj->_logfilename();
  open($obj->{'_fh'}, ">>$fn") or die "Unable to open log file $fn: $!";
  $obj->{'_fh'}->autoflush(1);
}

sub set_key {
  my $obj = shift;
  my $key = shift;

  my $okey = $obj->{'_key'};

  if($key ne $okey) {
     $obj->{'_key'} = $key;
     $obj->_reopen();
  }

  $obj->log("====> $key <=====") if(!$obj->_eventsplit());
}

sub _eventsplit_defined {
  my $obj = shift;
  my $dfwfw_conf = shift || $obj->{'_dfwfw_conf'};

  return 1 if(($dfwfw_conf)&&(defined($dfwfw_conf->{'log_split_by_event'})));

  return 0;
}

sub _eventsplit {
  my $obj = shift;
  my $dfwfw_conf = shift || $obj->{'_dfwfw_conf'};

  return $dfwfw_conf->{'log_split_by_event'} if($obj->_eventsplit_defined($dfwfw_conf));

  return 1;
}
sub _cursplitname {
  my $obj = shift;

  my $re = time()."-".$obj->{'_key'}.".log";

  return $re;
}

sub _logpath_defined {
  my $obj = shift;
  my $dfwfw_conf = shift || $obj->{'_dfwfw_conf'};
  return 1 if(($dfwfw_conf)&&(defined($dfwfw_conf->{'log_path'})));

  return 0;
}
sub _logpath {
  my $obj = shift;
  my $dfwfw_conf = shift || $obj->{'_dfwfw_conf'};
  return $dfwfw_conf->{'log_path'} if($obj->_logpath_defined($dfwfw_conf));

  return 0;
}

sub _logfilename {
  my $obj = shift;

  my $es = $obj->_eventsplit();
  if($obj->_logpath_defined()) {

    my $re = $obj->{'_dfwfw_conf'}->{'log_path'};
    $re.= "/".$obj->_cursplitname() if($es);
    return $re;
  }


  my $re = "/var/log/dfwfw/".($es ? $obj->_cursplitname() : "dfwfw.log");
  return $re;
}
sub new_config {
  my $obj = shift;
  my $dfwfw_conf = shift;

  my $o_es = $obj->_eventsplit();
  my $o_logpath = $obj->_logpath();
  my $n_es = $obj->_eventsplit($dfwfw_conf);
  my $n_logpath = $obj->_logpath($dfwfw_conf);

  $obj->{'_dfwfw_conf'} = $dfwfw_conf;

  $obj->set_key("NEW_LOG")  if(($o_es != $n_es)||($o_logpath ne $n_logpath));
}

sub new {
  my $class = shift;
  my $dfwfw_conf = shift;

  my $re = {
    "_dfwfw_conf"=>$dfwfw_conf,
    "_key"=> "init"
  };
  my $bre = bless $re, $class;

  return $bre;
}

sub DESTROY {
  my $self = shift;
  $self->{'_fh'}->close() if ($self->{'_fh'});
}

1;
