#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use File::Slurp;
use Test::Simple tests => 4;

BEGIN {
 push @INC, "$Bin/..";
}
use PreJSON::Parser;

write_file("test1.json", '{
  "node1": "test1",
  @|include:test2.json|
}');
write_file("test2.json", '  "node2": "test2",
  @|include:test3.json|');
write_file("test3.json", '# this is a comment here
  "node3": "test3"');


my $f = read_file("test1.json");
my $h = PreJSON::Parser::decode($f, undef, 0);

for(my $i = 1; $i <= 3; $i++) {
   unlink("test$i.json");

   my $k = "node$i";
   ok( $h->{$k} eq "test$i" );
   delete $h->{$k};
}

ok (scalar keys %$h == 0 );

