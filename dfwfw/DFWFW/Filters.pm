package DFWFW::Filters;

use DFWFW::Config;


sub match_sd {
  my ($class, $ref, $node1, $node2) = @_;

  my $value1 = $node1->{ $ref->{'field'} };
  if(!defined($value1)){
     # this might be possible when a (dead) container is not yet detached from a network

     ### $ref->{'field'} not defined in: $node1
     return;
  }

  my $value2 = $node2->{ $ref->{'field'} };
  if(!defined($value2)){
     # this might be possible when a (dead) container is not yet detached from a network

     ### $ref->{'field'} not defined in: $node2
     return;
  }

  #print "matching $value1 => $value2 vs $ref->{'value'}\n";

  return 1 if($ref->{'opcb'}($value1."=>".$value2, $ref->{'value'}));

}


sub match {
  my ($class, $ref, $node) = @_;

  my $value = $node->{ $ref->{'field'} };
  if(!defined($value)){
     # this might be possible when a (dead) container is not yet detached from a network

     ### $ref->{'field'} not defined in: $node
     return;
  }

  return 1 if($ref->{'opcb'}($value, $ref->{'value'}));

}


sub filter_networks_by_ref {
  my $class = shift;
  my $docker_info = shift;
  my $ref = shift;
  my @nets = values %{$docker_info->{'network_by_name'}};

  return DFWFW::Filters->filter_array_by_ref($ref, \@nets);
}

sub filter_array_by_ref {
  my $class = shift;
  my $ref = shift;
  my $list = shift;

  my @re;
  for my $c (@$list) {
     next if(!DFWFW::Filters->match($ref, $c));

     push @re, $c;
  }

  return \@re;
}

sub filter_hash_by_ref {
  my $class = shift;
  my $ref = shift;
  my $list = shift;

  my @re;
  for my $key (keys %$list) {
     my $field = $ref->{'field'};
     ### matching hash by ref: $key
     ###  for: $field
     next if(!DFWFW::Filters->match($ref, $list->{$key}));

     push @re, $key;
  }

  return \@re;
}


sub filter_hash_by_sd_ref {
  my $class = shift;
  my $ref = shift;
  my $list = shift;

  my @re;
  for my $key1 (keys %$list) {
    for my $key2 (keys %$list) {
      next if($key1 eq $key2);

      my $field = $ref->{'field'};
      ### matching hash sd by ref: $key1
      ### matching hash sd by ref: $key2
      ###  for: $field
      next if(!DFWFW::Filters->match_sd($ref, $list->{$key1}, $list->{$key2}));

      push @re, {src=> $key1, dst=> $key2};
    }
  }

  return \@re;
}


sub filter_hash_by_name {
  my $class = shift;
  my $name = shift;
  my $list = shift;

  my %n = ("name"=> "Name == $name");
  DFWFW::Config->parse_container_ref(\%n, "name");

  return DFWFW::Filters->filter_hash_by_ref($n{"name-ref"}, $list);
}

1;
