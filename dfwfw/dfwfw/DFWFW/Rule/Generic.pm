package DFWFW::Rule::Generic;

use parent "DFWFW::Rule::Base";

use DFWFW::Config;
use Data::Dumper;
use experimental 'smartmatch';

sub _parse {

  my $rule = shift;

  my $node = shift;

  my @extra_keys = @_;

  my @generic_keys = ("action","filter");
  my @keys = (@generic_keys, @extra_keys);

  DFWFW::Rule::Base->validate_keys($node, @keys);

  DFWFW::Config->filter_test($node);

   for my $extra (@extra_keys) {
      if($extra eq "action") {
         DFWFW::Config->action_test($node);
      }elsif($extra =~ /container/) {
         DFWFW::Config->parse_container_ref($node, $extra);
      }elsif($extra eq "expose_port") {
         DFWFW::Config->parse_expose_port($node);
      }elsif($extra =~ /network/) {
         DFWFW::Config->parse_network_ref($node, $extra);
      } else {
         die "No parsing handler for: $extra";
      }
  }

  if(($node->{"src_dst_container"})&&(($node->{"src_container"})||($node->{"dst_container"}))) {
      die "Next to src_dst_container no src_container nor dst_container keys can be present";
  }

}

sub build {
  my $rule = shift;
  my $docker_info = shift;
  my $re = shift;

  die "Abstract, not implemented";
}


1;
