package WebService::Docker::API;

use warnings;
use strict;
use LWP::UserAgent;
use URI;
use JSON::XS;

# Minimalistic implementation of the Docker proto inspired by Net::Docker

sub new {
    my $class = shift;
    my $docker_socket = shift || "http:/var/run/docker.sock/";

    if ( $docker_socket !~ m!http://! ) {
        require LWP::Protocol::http::SocketUnixAlt;
        LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocketUnixAlt' );
    }
    my $ua = LWP::UserAgent->new;

    my $obj = {
      _docker_socket => $docker_socket,
      _ua => $ua,
    };
    bless $obj, $class;

    return $obj;
}

sub _uri {
    my ($self, $uri, %options) = @_;
    my $re = URI->new($self->{'_docker_socket'} . $uri);
    $re->query_form(%options);
    return $re;
}

sub _byRes {
  my $self = shift;
  my $res = shift;
  my $body = shift || $res->decoded_content;

    if (($res->content_type eq 'application/json') && ($body)) {
        return decode_json($body);
    }

  return $body;

}

sub _body_callback_wrapper {
     my ($self, $data, $response, $protocol) = @_;

  $self->{'_body_callback'}->($self->_byRes($response, $data));

}

sub get {
  my $self = shift;
  my $uri = shift;

  my $cb  = sub { $self->_body_callback_wrapper(@_);  };

  my $urio = $self->_uri($uri);
  my $res = $self->{'_body_callback'} ? $self->{'_ua'}->get($urio, ':content_cb' => $cb) : $self->{'_ua'}->get($urio);

  die "Docker request was unsuccessful:\n".$res->as_string if(!$res->is_success);

  return $self->_byRes($res);

}

sub post {
  my $self = shift;
  my $uri = shift;
  my %options = shift;

  my $cb  = sub { $self->_body_callback_wrapper(@_);  };

  my $input = encode_json(\%options);
  my $res = $self->{'_body_callback'} ?
         $self->_ua->post($self->_uri($uri), ':content_cb' => $cb, 'Content-Type' => 'application/json', Content => $input) :
         $self->_ua->post($self->_uri($uri), 'Content-Type' => 'application/json', Content => $input);

  return $self->_byRes($res);
}

sub container_info {
  my $self = shift;
  my $container = shift;
  return $self->get("/containers/$container/json");
}

sub containers {
  my $self = shift;
  return $self->get("/containers/json");
}
sub networks {
  my $self = shift;
  return $self->get("/networks");
}

sub set_body_callback {
  my ($self, $callback) = @_;
  $self->{'_body_callback'} = $callback;
}

sub set_headers_callback {
  my ($self, $callback) = @_;
  $self->{'_ua'}->add_handler("response_header"=>$callback);
}

sub events {
  my ($self, $callback) = @_;
  $self->set_body_callback($callback);
  return $self->get('/events');
}

1;
