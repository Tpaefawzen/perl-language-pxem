package Language::Pxem::DataType;

use strict;
use warnings;

use Carp;

# Constructor
sub new {
  my $cls = shift;

  bless {
    stack => [],
    register => undef,
  }, $cls;
}

# member getter/setter
sub stack {
  my $self = shift;
  @{ $self->{stack} };
}

# I/O
# depends on __putc, __putn, __getc, __getn
sub cmd_p {
  my $self = shift;
  $self->cmd_o while ( $self->stack );
}

sub cmd_o {
  my $self = shift;
  my $x = $self->cmd_s;
  $self->__putc($x) if defined $x;
}

sub cmd_n {
  my $self = shift;
  my $x = $self->cmd_s;
  $self->__putn($x) if defined $x;
}

sub cmd_i {
  my $self = shift;
  my $x = $self->getc;
  $self->__getc($self->stack, $x);
}

sub cmd__ {
  my $self = shift;
  my $x = $self->getn;
  $self->__getn($self->stack, $x);
}

# I/O deps, must be implemented
# __getc, __getn accept an integer but doesn't need to care for undef.
# __putc, __putn accept nothing and return an integer so cmd_i and cmd__ pushes the value.
sub __getc { ... }
sub __getn { ... }
sub __putc { ... }
sub __putn { ... }

# Stack operation
sub cmd_c {
  my $self = shift;
  my $stack = $self->{stack};
  if ( @{ $stack } > 0 ) {
    push @{ $self->{stack} }, $stack->[$#{ $stack }];
  }
}

# May return a value unless empty
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

# process fork
sub cmd_e {
  my $self = shift;
  my $new = (ref $self)->new;
  @{ $new->{stack} } = $self->stack;
  return $new;
}

# How do I get random function, on-negative handler?
sub cmd_r {
  my $self = shift;
  my $x = $self->cmd_s;
  push @{ $self->{stack} }, $self->__rand($x) if defined $x;
}

# Must obtain an integer to return another integer.
sub __rand {
  my ($self, $x) = @_;
  return rand($x);
}

# Loop beginners. Return true if must enter loop, false if must break loop.
sub cmd_w {
  my $self = shift;
  my $x = $self->cmd_s;
  defined $x or return $self->__empty_handler, "w";
  return $x != 0;
}

sub cmd_x {
  my $self = shift;
  $self->__compare, "x";
}

sub cmd_y {
  my $self = shift;
  $self->__compare, "y";
}

sub cmd_z {
  my $self = shift;
  $self->__compare, "z";
}

# Two values comparison for loop
sub __compare {
  my ($self, $cond) = @_;
  return $self->__empty_handler, $cond if $self->stack < 2;

  my $x = $self->cmd_s;
  my $y = $self->cmd_s;

  my %cond = (
    x => sub { $_[0] < $_[1] },
    y => sub { $_[0] > $_[1] },
    z => sub { $_[0] == $_[1] },
  );
  return $cond{$cond}->($x, $y);
}

# Must return bool.
sub __empty_handler {
  my ($self, $cond) = @_;
  1; # As in pxemi or RPxem
}

# Loop ender.
sub cmd_a { } # obviously nop

# Register operation.
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

# Nothing to do.
sub cmd_d {} # Nothing. Stack concat can be done by C<<push @{ $self->{stack} }, $other->stack>>

# Arithmetic operations.
# Subroutine names cannot have symbol name, so usage: $pxem->opr("+"), $cmd->opr("!") or so
sub opr {
  my ($self, $opr) = @_;

  # Empty is NOP!
  return if $self->stack < 2;

  my $x = $self->cmd_s;
  my $y = $self->cmd_s;

  # Some operators need $x >= $y so $x - $y or $x / $y or $x % $y.
  my $needCmp = $opr == '-' || $opr == '$' || $opr == '%';
  ($y, $x) = sort { $self->__arith_cmp } $x, $y if $needCmp; # NOTE accending order so 1,2 not 2,1

  # Exceptional behavior
  $self->__handle_zerodiv($opr, $x, $y) and return;
  $self->__handle_overflow($opr, $x, $y) and return;
  $self->__handle_underflow($opr, $x, $y) and return;

  # Finally
  my %oprs = (
    '+' => sub { $_[0] + $_[1] },
    '-' => sub { $_[0] - $_[1] },
    '!' => sub { $_[0] * $_[1] },
    '$' => sub { int($_[0] / $_[1]) },
    '%' => sub { $_[0] % $_[1] },
  );

  my $result = $oprs{$opr}->($x, $y);
  push @{ $self->{stack} }, $result
}

# <=> thing for sort
sub __arith_cmp {
  $a <=> $b;
}

# For arithmetic operations.
# These do something if any.
# my ($self, $opr, $x, $y) = @_;
# Must return true if and only if has handled.
sub __handle_zerodiv { undef }
sub __handle_overflow { undef }
sub __handle_underflow { undef }

# Stack operation
# Concatenated as is.
sub Push {
  my $self = shift;
  push @{ $self->{stack} }, @_;
}

# Literal push; order reversed.

# List of integers.
sub push_literal_n {
  my $self = shift;
  push @{ $self->{stack} }, reverse @_;
}

# A string.
sub push_literal_s {
  my ($self, $str) = @_;
  ...
}

1;

=pod

=head1 NAME

Language::Perl::DataType - Pxem data structure: stack and nullable register

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

A stack and a nullable register.

For each Pxem command C<.x> where C<x> is the character, implements method C<cmd_x> in lowercase.
Arithmetic operators are implemented as method C<opr> who accepts the command name as first argument.

=head1 MEMBERS

=over

=item C<{stack}>

An array of integers.

=item C<{register}>

C<undef> or an integer.

=back

=head1 MEMBER ACCESORS

=over

=item C<stack($self)>

Return C<<@{ $self->{stack} }>>.

=back

=head1 CONSTRUCTORS

=over

=item C<new($cls)>

Create a pair of an empty stack and an empty register.

=item C<cmd_e($self)>

Create and return a fork of C<$self>; the C<{stack}> is inherieted but the C<{register}> is C<undef>.

=back

=head1 METHODS

Modules with name starting with two underscores C<__> are considered to be overloadable methods that you should customize.

Modules with name starting with C<cmd_> are as in Pxem command lowercase except C<+>, C<->, C<!>, C<$>, C<%>;
these five methods are implemented as C<opr> method.

=head2 Pxem commands

=over

=item C<cmd_p($self)>, C<cmd_o($self)>, C<cmd_n($self)>

Output commands.
C<cmd_p> outputs every item in the stack as characters.
C<cmd_o> and C<cmd_n> outputs top item of the stack as a character and a number respectively if any.

Depends on C<__putc>, C<__putn>.

=item C<cmd_i($self)>, C<cmd__($self)>

Input commands.
Get a character or a number respectively to push onto the stack.

Depends on C<__getc>, C<__getn>.

=item C<cmd_c($self)>

Duplicate top item of the stack if any.

=item C<cmd_s($self)>

Pop an item from the stack and return it if any.

On the Pxem language the command just discards the top value if any.

=item C<cmd_v($self)>

Reverse the order of the stack.

=item C<cmd_f($self)>

Push content of the stack as literal.
B<This method is unimplemented to leave the task to define the content of the file to the inherented package.>

=item C<cmd_e($self)>

See "CONSTRUCTORS".

=item C<cmd_r($self)>

Pop a value if any. If so, get a random integer from 0 up to the value (exclusive).

Depends on C<__rand>.

=item C<cmd_w($self)>, C<cmd_x($self)>, C<cmd_y($self)>, C<cmd_z($self)>

Pop one or two values from the stack if any.
Return a boolean value to indicate whether the program counter should enter the loop.
These commands construct the beginning of the loop.

C<cmd_w> pops one value to test whether it is NOT zero.

Other three methods pop two values to test comparison as in C<__compare>.

Depends on C<__empty_handler>, C<__compare>.

=item C<cmd_a($self)>

Do nothing; this command indicates end of loop but the task to handle the loop is left to
the child of this package.

=item C<cmd_t($self)>

Pop a value if any. If so, store the value to the register.

=item C<cmd_m($self)>

Push a value in the register unless empty.

=item C<cmd_d($self)>

Do nothing; this command indicates to return from the subroutine so 

=back

=cut
