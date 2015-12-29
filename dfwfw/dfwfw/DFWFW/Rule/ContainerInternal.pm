package DFWFW::Rule::ContainerInternal;

use parent "DFWFW::Rule::Base";

use DFWFW::Config;
use Data::Dumper;
use experimental 'smartmatch';

sub parse {
  my $rule = shift;
  my $node = shift;

  my @nodes = ("container","rules","table");

  DFWFW::Rule::Base->validate_keys($node, @nodes);

   die "Container not specified" if(!DFWFW::Config->parse_container_ref($node, "container"));
   $node->{'table'}="filter" if(!$node->{'table'});

   DFWFW::Iptables->validate_table($node->{'table'});

   die "No rules specified" if(!$node->{'rules'});
   my $t = ref($node->{'rules'});
   die "Invalid rule node" if($t !~ /^(ARRAY)?$/);

   $node->{'rules'} = [$node->{'rules'}] if($t eq "");

}

sub build {
  my $self = shift;
  my $docker_info = shift;
  my $rules_to_commit = shift;

  my $rule = $self->{'node'};

       my $cts = DFWFW::Filters->filter_hash_by_ref($rule->{'container-ref'}, $docker_info->{'container_by_name'});
       if(!scalar @$cts) {
           $self->mylog("Container internals: rule #$rule->{'no'} does not match any containers, skipping rule");
           return;
       }

       for my $ctname (@$cts) {
         $rules_to_commit->{$ctname}{$rule->{'table'}} .= "# rule #$rule->{'no'}:\n";
         for my $iptables_line (@{$rule->{'rules'}}) {
            $rules_to_commit->{$ctname}{$rule->{'table'}} .= "$iptables_line\n";
         }
         $rules_to_commit->{$ctname}{$rule->{'table'}} .= "\n";
       }
}


1;
