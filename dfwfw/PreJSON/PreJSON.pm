package PreJSON;

use warnings;
use strict;
use JSON::XS;
use File::Slurp;

sub decode {
  my $text = shift;
  my $cb = shift;
  my $debug = shift;

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
         $re =~ s/#.*//g;  # strip out comments
         return $re || "";
     }

     if(defined $cb) {
        my $x = $cb->($k,$v);
        return $x if(defined $x);
     }

     die "Invalid prejson key $k with value $v";
  };

  $text =~ s/@\|\s*(\w+)\s*:\s*(.+?)\s*\|/$proc->($1,$2)/ge;

  if($debug) {
     print STDERR $text;
  }

  return decode_json($text);
}


1;
