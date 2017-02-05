#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Data::Dumper;
use FindBin qw($Bin);
use JSON::XS;
use Getopt::Long;

BEGIN {
 push @INC, "$Bin", "$Bin/WebServiceDocker/lib", "$Bin/ConfigHostsFile/lib", "$Bin/PreJSONParser/lib";
}
use WebService::Docker::API;
use WebService::Docker::Info;
use DFWFW::Config;
use DFWFW::Fire;
use DFWFW::Iptables;
use DFWFW::Logger;

local $| = 1;


my ($c_dry_run, $c_one_shot) = (0, 0);

  GetOptions ("dry-run" => \$c_dry_run,
              "one-shot"   => \$c_one_shot)
  or die("Usage: $0 [--dry-run] [--one-shot]");


my $dfwfw_conf;
my $iptables = new DFWFW::Iptables(\&mylog, $c_dry_run);
my $fire = new DFWFW::Fire(\&mylog, $iptables);
my $logger = new DFWFW::Logger();


my $docker_info;

local $SIG{TERM} = sub {
  $logger->set_key("TERM");
  mylog("Received term signal, exiting");
  exit;
};
local $SIG{ALRM} = sub {
  $logger->set_key("ALRM");
  mylog("Received alarm signal, rebuilding Docker configuration");
  $fire->fetch_docker_configuration();
};
local $SIG{HUP} = sub {
  $logger->set_key("HUP");
  mylog("Received HUP signal, rebuilding everything");
  return if(!on_hup(1));

  $fire->rebuild();
};


on_hup();

$fire->init_dfwfw_rules();

monitor_changes();

sub on_hup {
  my $safe = shift;

  return if(!parse_dfwfw_conf($safe));

  $fire->fetch_docker_configuration();
  $fire->init_user_rules();

  return 1;
}




sub event_cb {
   my $d = shift;
   return if(!$d);

   my $event = "";
   if(($d->{'Type'})&&($d->{'Action'})&&($d->{'Actor'})) {
      # Docker 1.10
      $event = $d->{'Action'};
      mylog("Docker event: $d->{'Type'}:$d->{'Action'}: ".encode_json($d->{'Actor'})) ;
   } else {
      $event = $d->{'status'} || "";
      mylog("Docker event: $d->{'status'} of $d->{'from'}");
   }

   return if(!$event || !($d->{'status'})) || ($d->{'status'} !~ /^(start|die)$/);

   my $eventstr = $event . ($d->{'from'} ? " - ".$d->{'from'} : "");
   mylog("Rebuilding DFWFW due to Docker event: $eventstr");

   $fire->fetch_docker_configuration();
   $fire->rebuild();
}

sub headers_cb {
   # first time HTTP headers arrived from the docker daemon
   # this is a tricky solution to reach a race condition free state

   mylog("Rebuilding Docker configuration due to new connection to Docker agent");
   $fire->fetch_docker_configuration();
   $fire->rebuild();

   if($c_one_shot) {
      mylog("Exiting, one-shot was specified");
      exit 0;
   }

}


sub monitor_changes {
   my $api = WebService::Docker::API->new($dfwfw_conf->{'docker_socket'});

   $api->set_headers_callback(\&headers_cb);

   while(1) {
      my $response = $api->events(\&event_cb);
      mylog("Docker events stream ended: $response\n");

      # We try to reconnect in a second. If we can't, the process will exit
      sleep(1);
   }
}






sub parse_dfwfw_conf {
  my $safe = shift;

  eval {
     my $new_start = $dfwfw_conf ? 0 : 1;

     my $new_dfwfw_conf = new DFWFW::Config(\&mylog);
     # success
     $dfwfw_conf = $new_dfwfw_conf;

     $logger->new_config($dfwfw_conf);
     $fire->new_config($dfwfw_conf);

     mylog("----------------------- DFWFW starting") if($new_start);

  }; 
  if($@) {
     mylog("Syntax error in configuration file:\n$@");
     if($safe) {
         mylog("Safe mode: reverting to original config and not proceeding to firewall ruleset rebuild");
         return 0;
     }

     die $@;
  }

  return 1;
}


sub mylog {
  my $msg = shift;

  $logger->log($msg);
}
