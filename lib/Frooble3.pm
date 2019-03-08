package Frooble3 {

  use strict;
  use warnings;
  use 5.028;

  sub dbh
  {
    state $dbh;
    $dbh ||= do {
      require DBI;
      DBI->connect('dbi:Pg:db=frooble3', 'frooble3', 'frooble3', { AutoCommit => 0, RaiseError => 1 });
    };
  }

  sub metacpan
  {
    state $mcpan;
    $mcpan ||= do {
      require MetaCPAN::Client;
      MetaCPAN::Client->new
    };
  }

  sub ct
  {
    state $ct;
    $ct ||= do {
      require Frooble3::CT;
      Frooble3::CT->new;
    };
  }

};

1;
