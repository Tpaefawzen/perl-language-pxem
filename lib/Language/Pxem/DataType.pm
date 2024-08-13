package Language::Pxem::DataType;

use strict;
use warnings;

use Carp;

sub new {
  my $cls = shift;

  bless {
    stack => [],
    register => undef,
  }, $cls;
}

# member getter/setter
sub stack {
  defined wantarray or return;

  my $self = shift;
  @{ $self->{stack} };
}

# I/O are out of this scope!
sub cmd_p { ... }
sub cmd_o { ... }
sub cmd_n { ... }
sub cmd_i { ... }
sub cmd__ { ... }

sub cmd_c {
  my $self = shift;
  my $stack = $self->{stack};
  if ( @{ $stack } > 0 ) {
    push @{ $self->{stack} }, $stack->[$#{ $stack }];
  }
}

sub cmd_s {
  my $self = shift;
  pop @{ $self->{stack} };
}

sub cmd_v {
  my $self = shift;
  @{ $self->{stack} } = reverse @{ $self->{stack} };
}

# How do I get my file content?
sub cmd_f { ... }

# I know it should be forked but really?
sub cmd_e { ... }

# How do I get random function, on-negative handler?
sub cmd_r { ... }

# idk for loops
sub cmd_w { ... }
sub cmd_x { ... }
sub cmd_y { ... }
sub cmd_z { ... }
sub cmd_a { } # obviously nop

sub cmd_t {
  my $self = shift;
  my $val = pop @{ $self->{stack} };
  $self->{register} = $val if defined $val;
}

sub cmd_m {
  my $self = shift;
  my $val = $self->{register};
  push @{ $self->{stack} }, $val if defined $val;
}

# Stack operation
sub Push {
  my $self = shift;
  push @{ $self->{stack} }, @_;
}

1;

=pod

=head1 NAME

Language::Perl::DataType - Pxem data structure

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

A stack and a nullable register.

=cut
