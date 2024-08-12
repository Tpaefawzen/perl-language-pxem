package Language::Pxem::Stack;

use strict;
use warnings;
use Carp;

sub new {
  my $cls = shift;
  bless {
    s => [],
  }, $cls;
}


sub push {
  my $self = shift;
  my $v = shift;
  push @{$self->{s}}, $v;
}

sub pop {
  my $self = shift;
  pop @{$self->{s}};
}

sub dup {
  my $self = shift;
  return if $self->empty;
  my $v = $self->pop;
  $self->push;
  $self->push;
}

sub reverse {
  my $self = shift;
  my @l = reverse $self->{s};
  $self->{s} = @l;
}

sub fork {
  my $self = shift;
  my $new = __PACKAGE__->new;
  my @l = $self->{s};
  $new->push($_) foreach CORE::reverse @l;
  $new;
}

sub concat {
  my $self = shift;
  my $other = shift;
  $self->push($_) foreach $other->{s};
}

sub empty {
  my $self = shift;
  $self->{s} == 0;
}

sub length {
  my $self = shift;
  length $self->{s};
}

sub can_arithmetic {
  my $self = shift;
  $self->length >= 2;
}

1;
