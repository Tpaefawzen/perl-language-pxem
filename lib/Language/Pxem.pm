package Language::Pxem;

use 5.038002;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';

# index 2*n is literal data, index 2*n+1 is command.
# This is token analyzer.
sub lex {
  my $src = shift;
  my @compiled;

  while ( $src ) {
    if ( $src =~ s/^(.*?)(\.[poni_csvferwxyzatmd+!$%-])//i ) {
      my $literal = $1;
      my $cmd = $2;
      $cmd =~ tr/A-Z/a-z/;
      push @compiled, $literal, $cmd;
    } else {
      push @compiled, $src;
      return @compiled;
      last;
    }
  }

  @compiled;
}

# Preloaded methods go here.
sub new {
    my $cls = shift;
    my $path = shift;

    bless {
        path => $path,
    }, $cls;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::Pxem - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Language::Pxem;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Language::Pxem, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
