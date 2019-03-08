package Frooble3::Importer {

  use strict;
  use warnings;
  use 5.026;
  use Moo;
  use experimental qw( signatures );
  use HTML::HTML5::Entities ();

  has dbh => (
    is       => 'ro',
    required => 1,
  );

  has sth_exists => (
    is      => 'ro',
    lazy    => 1,
    default => sub ($self) {
      $self->dbh->prepare(q{ SELECT true AS exists FROM report_data WHERE guid = ? });
    },
  );

  my @fields = qw( dist date grade guid osname osvers platform perl reporter version );

  has sth_insert => (
    is      => 'ro',
    lazy    => 1,
    default => sub ($self) {
      $self->dbh->prepare(qq{
        INSERT INTO report (@{[ join(',', @fields) ]}) VALUES (@{[ join(',', map { '?' } @fields) ]})
      });
    },
  );

  sub exists ($self, $guid)
  {
    my $sth = $self->sth_exists;
    $sth->execute($guid);
    my $h = $sth->fetchrow_hashref;
    !!$h->{exists};
  }

  sub ingest ($self, @reports)
  {
    my %count;

    foreach my $report (@reports)
    {
      my %r = %$report;
      next if $self->exists($r{guid});
      $count{$r{grade}}++;
      $r{reporter} = HTML::HTML5::Entities::decode_entities($r{reporter});
      my @values = map { delete $r{$_} } @fields;

      if(%r)
      {
        print STDERR Dump($report);
        die "unknown extra fields: @{[ sort keys %r ]}";
      }

      $self->sth_insert->execute(@values);
    }

    $self->dbh->commit;

    %count;
  }

};

1;
