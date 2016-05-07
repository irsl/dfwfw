package PreJSON::Parser;

use warnings;
use strict;
use JSON::XS;
use File::Slurp;

sub _prepare {
  my $text = shift;
  my $cb = shift;

  #strip out comments:
  $text =~ s/#.*//g;

  my $proc = sub {
     my ($k, $v) = @_;
     # print "stuff: $k x $v\n";

     if($k eq "include") {
         my $re = "";
         for my $f (glob $v) {
            $re .= read_file($f);
         }
         $re =~ s/#.*//g;
         return $re;
     }

     if(defined $cb) {
        my $x = $cb->($k,$v);
        return $x if(defined $x);
     }

     die "Invalid prejson key $k with value $v";
  };

  my $ac = 0;
  while(my $c = $text =~ s/@\|\s*(\w+)\s*:\s*(.+?)\s*\|/$proc->($1,$2)/ge) {
     $ac++;
     die "Too many internal substitutions" if($ac > 100);
  }

  return $text;
}

sub decode {
  my $text = shift;
  my $cb = shift;
  my $debug = shift;

#print "x $text\n";exit;
# $cb, $debug, y\n";
#print "debug: $debug\n";

  $text = _prepare($text, $cb);

  if($debug) {
     print STDERR $text;
  }

  return decode_json($text);
}


1;
