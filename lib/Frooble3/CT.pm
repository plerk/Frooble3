package Frooble3::CT {

  use strict;
  use warnings;
  use 5.026;
  use Moo;
  use experimental qw( signatures );
  use Cpanel::JSON::XS ();

  has ua => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      require LWP::UserAgent;
      my $ua = LWP::UserAgent->new;
      $ua->default_header( Accept => 'application/json' );
      $ua;
    },
  );

  has base_url => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      require URI;
      URI->new('https://api.cpantesters.org');
    },
  );

  sub summary ($self, $dist=undef, $version=undef)
  {
    my $path = "/v3/summary";
    $path .= "/$dist"    if defined $dist;
    $path .= "/$version" if defined $version;

    my $url = $self->base_url->clone;
    $url->path($path);

    my $res = $self->ua->get($url);

    unless($res->is_success)
    {
      die $res->status_line;
    }

    Cpanel::JSON::XS::decode_json($res->decoded_content)->@*;
  }

};

1;
