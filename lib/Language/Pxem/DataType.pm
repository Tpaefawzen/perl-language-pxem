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
  my $x = $self->__getc;
  push @{ $self->{stack} }, $x;
}

sub cmd__ {
  my $self = shift;
  my $x = $self->__getn;
  push @{ $self->{stack} }, $x;
}

# I/O deps, must be implemented
# __putc, __putn accept an integer but doesn't need to care for undef.
# __getc, __getn accept nothing and return an integer so cmd_i and cmd__ pushes the value.
sub __putc { ... }
sub __putn { ... }
sub __getc { ... }
sub __getn { ... }

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
  $self->__srand unless $self->{has_done_srand};
  $self->{has_done_srand} = 1;
  my $x = $self->cmd_s;
  push @{ $self->{stack} }, $self->__rand($x) if defined $x;
}

# Must obtain an integer to return another integer.
sub __rand {
  my ($self, $x) = @_;
  return $self->__int(rand($x));
}

sub __srand {
  srand();
}

# Loop beginners. Return true if must enter loop, false if must break loop.
sub cmd_w {
  my $self = shift;
  my $x = $self->cmd_s;
  defined $x or return $self->__empty_handler("w");
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
  return $self->__empty_handler($cond) if $self->stack < 2;

  my $x = $self->cmd_s;
  my $y = $self->cmd_s;

  my %cond = (
    x => $x < $y,
    y => $x > $y,
    z => $x != $y,
  );
  return $cond{$cond};
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
  $self->__empty_handler_t unless defined $val;
}

sub __empty_handler_t {}

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

  return if $self->stack < 2;

  my %cmds = qw(
    + __add
    - __sub
    ! __mul
    $ __div
    % __mod
  );
  my $cmd = $cmds{$opr};
  $self->$cmd;
}

sub __add {
  my $self = shift;
  $self->Push($self->cmd_s() + $self->cmd_s());
}

sub __sub {
  my $self = shift;
  $self->Push(abs($self->cmd_s() - $self->cmd_s()));
}

sub __mul {
  my $self = shift;
  $self->Push($self->cmd_s() * $self->cmd_s());
}

sub __div {
  my $self = shift;
  my ($y, $x) = sort { $self->__arith_cmp } $self->cmd_s(), $self-cmd_s();
  $self->__handle_zerodiv('$', $x, $y);
  $self->Push($x % $y);
}

sub __mod {
  my $self = shift;
  my ($y, $x) = sort { $self->__arith_cmp } $self->cmd_s(), $self-cmd_s();
  $self->__handle_zerodiv('%', $x, $y);
  $self->Push($self->__int($x / $y));
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

# The way to make an integer.
sub __int {
    my ($self, $x) = @_;
    int($x);
}

# Stack operation
# Concatenated as is.
sub Push {
  my $self = shift;
  push @{ $self->{stack} }, @_;
}

1;

__END__

=pod

=head1 NAME

Language::Pxem::DataType - Pxem data structure: stack and nullable register

=head1 SYNOPSIS

    use Language::Pxem::DataType;

    my $storage = Language::Pxem::DataType->new;
    $storage->Push(1,2,3,4,5,6,7,8,9);

    for ( qw/ p o n i _ c s v f e r w x y z a t m d / ) {
        my $method_name = "cmd_$_";
        $return = $storage->$method_name;
    }

    for ( qw/ + - ! $ % / ) {
        $storage->opr($_);
    }

=head1 DESCRIPTION

A stack and a nullable register.

For each Pxem command C<.x> where C<x> is the lowercase character, method C<cmd_x> is implemented.
Arithmetic operating commands such as C<.+>, C<.$> are implemented as a method C<opr>;
it accepts a command character for first argument.

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

    my @current_stack = $self->stack;

Return C<<@{ $self->{stack} }>>.

=back

=head1 CONSTRUCTORS

=over

=item C<new($cls)>

    my $storage = Language::Pxem::DataType->new;

Create a pair of an empty stack and an empty register.

=item C<cmd_e($self)>

    my $forked = $self->cmd_e;

Create and return a fork of C<$self>; the C<{stack}> is inherieted from C<$self> but the C<{register}> is C<undef>.

=back

=head1 METHODS

Modules with name starting with two underscores C<__> are considered to be overloadable methods that you should customize.

Modules with name starting with C<cmd_> are as in Pxem command lowercase except C<+>, C<->, C<!>, C<$>, C<%>;
these five methods are implemented as C<opr> method.

=head2 Pxem commands

=over

=item C<cmd_p($self)>, C<cmd_o($self)>, C<cmd_n($self)>

    $self->cmd_p; # Ditto for cmd_o, cmd_n

Output commands.
C<cmd_p> outputs every item in the stack as characters to standard output.
After that the stack is empty.
C<cmd_o> and C<cmd_n> outputs top item of the stack as a character and a number respectively if any.

Depends on C<__putc>, C<__putn>.

=over

=item C<__putc($self, $integer)>

=item C<__putn($self, $integer)>

    package MyPxem;
    use parent qw(Language::Pxem::DataType);

    sub __putc {
        my ($self, $integer) = @_;
        print $self->{fout} chr($integer);
    }

    sub __putn {
        my ($self, $integer) = @_;
        print $self->{fout} $integer;
    }
    
    package main;
    my $self = MyPxem->new;
    $self->__putc($integer);
    $self->__putn($integer);

C<__putc> and C<__putn> are unimplemented by default.
They shall take an C<$integer> value to output a character with
such codepoint and a decimal integer representation of the value
to the I<standard output> respectively. 

Error-handling is implementation defined.

=back

=item C<cmd_i($self)>, C<cmd__($self)>

    $self->cmd_i; # Ditto for cmd__

Input commands.
Get a character or a number from standard input respectively to push onto the stack.

Depends on C<__getc>, C<__getn>.

=over

=item C<__getc($self)>, C<__getn($self)>

    package MyPxem;
    use parent qw(Language::Pxem::DataType);
    
    sub __getc {
        my $self = shift;
        if ( defined (my $c = $self->{ungetbuf}) ) {
            $self->{ungetbuf} = undef;
            return $c;
        }
        return ord getc $self->{fin} or -1;
    }

    sub __getn {
        my $self = shift;
        ...; # Implement to take $1 from /^\s([+-]?[0-9]+)/ from $self->{fin}
    }

    package main;
    my $self = MyPxem->new;
    my $integer = $self->__getc;
    my $integer = $self->__getn;

Unimplemented by default.
They shall take no arguments to return an integer, not a character of string.
C<__getc> shall read a character from the I<standard input> to return its codepoint value.
If failed, -1 shall be returned.
C<__getn> shall do what C<scanf("%d", &n)> in the C language does to return the integer value C<n>;
it is implementation-defined in case it failed.

=back

=item C<cmd_c($self)>

    $self->cmd_c;

Duplicate top item of the stack if any.

=item C<cmd_s($self)>

    my $value = $self->cmd_s;
    unless ( defined $value ) {
        # Do something when stack is empty
    } else {
        # Do something when popped something
    }

Pop an item from the stack and return it if any.

On the Pxem language the command just discards the top value if any.

It does:

    pop @{ $self->{stack} };

=item C<cmd_v($self)>

    $self->cmd_v;

Reverse the order of the stack.

=item C<cmd_f($self)>

    $self->cmd_f;

I<Unimplemented by default.>
Push content of the file as literal data;
last character is pushed first then second to last, third to last and so on;
the first character shall be top of the stack.

=item C<cmd_e($self)>

    my $forked = $self->cmd_e;

See "CONSTRUCTORS".

=item C<cmd_r($self)>

    $self->cmd_r;

Random value obtainer.
Pop a value if any. If so, get a random integer from 0 up to the value (exclusive).

Depends on C<__srand>, C<__rand>.

=over

=item C<__srand($self)>

    $self->__srand;

This method shall set initial statement for C<__rand> method.
Shall be called only once if.

=item C<__rand($self, $upto)>

    my $int = $self->__rand($self, $upto);

Given a positive integer C<$upto>, C<__rand> shall return an integer randomly chosen from 0 to C<$upto>,
excluding C<$upto>.
Unspecified for non-positive integer C<$upto>, but I think you can extend this method so
it can accept non-negative integer so it returns a negative integer.
For example:

    package MyPxem;
    use parent qw(Language::Pxem::DataType);

    sub __rand {
        my ($self, $upto) = @_;
        my $sign = 1;
        ($upto, $sign) = (-$upto, -1) if $upto<0;
        $sign * $self->SUPER::__rand($upto);
    }

=back

=item C<cmd_w($self)>, C<cmd_x($self)>, C<cmd_y($self)>, C<cmd_z($self)>

    my $bool = $self->cmd_w; # Ditto for cmd_x, cmd_y, cmd_z

Loop beginners.
Pop one or two values from the stack if any.
Return a boolean value to indicate whether the program counter should enter the loop.
These commands construct the beginning of the loop.

C<cmd_w> pops one value to test whether it is NOT zero.

C<cmd_x>, C<cmd_y>, C<cmd_z> pop two values;
let top value C<$x> and second top value C<$y>;
C<cmd_x>, C<cmd_y>, and C<cmd_z> return true if
C<<$x<$y>>, C<<$x>$y>>, C<<$x!=$y>> respectively.

If stack is empty when C<cmd_w> is called, or
if stack has less than two items when other three methods are callled,
the C<__empty_handler> shall be called with one of C<qw(w x y z)> as first argument
to the method C<__empty_handler> to indicate which of the four methods C<cmd_w>, C<cmd_x>, C<cmd_y>, C<cmd_z> called the handler;
the result of C<__empty_handler> is returned as the result of this method.

Depends on C<__empty_handler>.

=over

=item C<__empty_handler($self, $cond)>

    my $bool = $self->__empty_handler("w"); # or "x", "y", "z"

This method shall determine whether the control should transfer inside the looping block
when the stack has inadequant items to decide the given C<$cond>ition.

=back

=item C<cmd_a($self)>

Do nothing; this command indicates end of loop but the task to handle the loop is left to
the child of this package.

=item C<cmd_t($self)>

    $self->cmd_t;

Pop a value if any. If so, store the value to the register.
If the stack is empty C<__empty_handler_t> is called.

=over

=item C<__empty_handler_t($self)>

    $self->__empty_handler_t;

This method shall be called when C<cmd_t> is called and the stack is empty;
by default it does nothing.

=back

=item C<cmd_m($self)>

    $self->cmd_m;

Push a value in the register unless empty.
If the register is empty nothing is done.

=item C<cmd_d($self)>

    $self->cmd_d;

Do nothing; this command indicates to return from the subroutine so 

=item C<opr($self, $chr)>

    $self->opr("+"); # one of q/ + - ! $ % /

Arithmetic operation to the stack.
If the stack has less than two items do nothing.
Else do arithmetic operation; pop top two items as arithmetic operands,
then push the arithmetic result.

Depends on C<__add>, C<__sub>, C<__mul>, C<__div>, C<__mod>.

=over

=item C<__add($self, $x, $y)>

=item C<__sub($self, $x, $y)>

=item C<__mul($self, $x, $y)>

=item C<__div($self, $x, $y)>

=item C<__mod($self, $x, $y)>

    my $result = $self->__add($self, $x, $y); # or __sub, __mul, __div, __mod

Arithmetic methods.
The C<$x> integer shall always be the first operand.

THe user can override these methods to deal with overflow, underflow, and/or zero division;
none of they are handled by default.

=back

=back

=head2 OTHER METHODS

=over

=item C<__int($self, $x)>

    $x = $self->__int($x);

Given C<$x> as either a string or a real number,
convert and return user-defined integer type.

It's C<int($x)> by default.

=item C<Push($self, @items)>

    $self->(1,2,3);

Equivalent to C<<push @{ $self->{stack} }, @items>>.

=back

=cut
