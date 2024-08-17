use strict;
use warnings;

use Test2::V0;
use Language::Pxem::DataType;

my $d = Language::Pxem::DataType->new;

diag("Now cmd_r");

my $e = Language::Pxem::DataType->new;
my @statistics;

$e->cmd_r;
is($e->{stack}, array { end(); }, "cmd_r [] -> []");

for ( 0 .. 100 ) {
  $e->Push(10);
  $e->cmd_r;
  my $v = $e->cmd_s;
  $statistics[$v]++;
  ok($v >= 0, "cmd_r [10] -> [>=0], got [$v]");
  ok($v < 10, "cmd_r [10] -> [<10], got [$v]");
}

my $note = "OBTW got this:";
for ( my $i = 0; $i < @statistics; $i++ ) {
  $note .= " [$i]: $statistics[$i]";
}
diag($note);


# Finally
done_testing;
