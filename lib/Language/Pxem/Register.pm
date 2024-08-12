package Language::Pxem::Register;

use strict;
use warnings;

sub new {
  my $cls = shift;
  bless {
    v => undef,
  }, $cls;
}

sub get {
  my $self = shift;
  $self->{v};
}

sub set {
  my $self = shift;
  my $v = shift;
  $self->{v} = $v;
}

1;
