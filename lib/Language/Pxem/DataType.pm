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

# I/O are out of this scope!
sub cmd_p { ... };
sub cmd_o { ... };
sub cmd_n { ... };
sub cmd_i { ... };
sub cmd__ { ... };

sub cmd_c {
  my $self = shift;
  my $stack = $self->{stack};
  if ( @{ $stack } ) {
    push @{ $stack }, $stack->[$#{ $stack }];
  }
}

sub Push {
  my $self = shift;
  push @{ $self->{stack} }, @_;
}

1;
