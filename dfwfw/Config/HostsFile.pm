package Config::HostsFile;

use warnings;
use strict;

sub new {
    my $class = shift;
    my $hostsfile = shift || "/etc/hosts";

    open(my $x,"<$hostsfile") or die "Cant open hostsfile ($hostsfile): $!";
    my @lines = <$x>;
    close($x);

    my $obj = {
      _lines => \@lines,
      _hosts_file => $hostsfile,
    };
    bless $obj, $class;

    return $obj;
}

sub _build_line {
  my $obj = shift;
  my $ip = shift;
  my $hostnames = shift;

  return "$ip ".join(" ", @$hostnames)."\n";
}

sub _processor {
  my $obj = shift;
  my $callback = shift;

  for my $l (@{$obj->{_lines}}) {
     next if(!defined($l));
     next if($l =~ /^[\s#]/);
     next if($l !~ /^([^\s]+)\s+(.+)/);
     my %parsed;
     $parsed{"ip"} = $1;
     $parsed{"rest"} = $2;
     my @hostnames = split /\s+/, $parsed{"rest"};
     $parsed{"hostnames"} = \@hostnames;
     $callback->(\$l, \%parsed);
     #$l = "ss\n";
     #undef($l);
  }
}

sub remove_host {
  my $obj = shift;
  my $host_to_remove = shift;

  $obj->_processor(sub {
     my $l = shift;
     my $parsed = shift;
     my @w;
     for my $host (@{$parsed->{'hostnames'}}) {
       if($host_to_remove ne $host) {
          push @w, $host;
       }
     }
     if(!scalar @w) {
          undef($$l) ;
          return;
     }

     $$l = $obj->_build_line($parsed->{'ip'}, \@w);
  });
}


sub update_host {
  my $obj = shift;
  my $host_to_update = shift;
  my $new_ip = shift;

  my $found = 0;
  $obj->_processor(sub {
     my $l = shift;
     my $parsed = shift;
     my @w;
     for my $host (@{$parsed->{'hostnames'}}) {
       if($host_to_update eq $host) {
          $found = 1;
          $$l = $obj->_build_line($new_ip, $parsed->{'hostnames'});
          return;
       }
     }
  });

  if(!$found) {
     push @{$obj->{'_lines'}}, $obj->_build_line($new_ip, [$host_to_update]);
  }
}

sub remove_ip {
  my $obj = shift;
  my $ip_to_remove = shift;

  $obj->_processor(sub {
     my $l = shift;
     my $parsed = shift;
     #print "in callback: $parsed->{'ip'} | @{$parsed->{'hostnames'}}\n";
     #print $obj->_build_line($parsed->{'ip'}, $parsed->{'hostnames'});

     if($parsed->{'ip'} eq $ip_to_remove) {
        #print "removing $ip_to_remove\n";
        undef($$l) ;
     }
  });

}

sub flush {
  my $obj = shift;
  my $dst_file = shift || $obj->{_hosts_file};

  #print "Flushing to $dst_file\n";
  open (my $x, ">$dst_file") or die "Cant open hosts file ($dst_file) for writing: $!";
  for my $l (@{$obj->{_lines}}) {
     next if(!defined($l));
     print $x $l;
  }
  close($x);

}

1;
