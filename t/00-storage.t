use strict;
use warnings;

use Test2::V0;
use Language::Pxem::DataType;

my $d = Language::Pxem::DataType->new;

diag("Testing initialized DataType");
is($d->{register}, U(), "Resiter should be empty");
is($d->{stack}, array { end(); }, "Stack should be empty");

diag("->Push()ing 16, 17, 18");
$d->Push(16, 17, 18);
is($d->{stack}, array { item 16; item 17; item 18; end(); }, "Should have ->Push()ed");

diag("Now cmd_s");
is($d->cmd_s, 18, "Should have popped 18");
is($d->cmd_s, 17, "Should have popped 17");
is($d->cmd_s, 16, "Should have popped 16");
is($d->cmd_s, U(), "Now should have been empty");

diag("Now cmd_c");
$d->cmd_c;
is($d->{stack}, array { end(); }, "cmd_c [] -> []");
$d->Push(16, 17, 18);
$d->cmd_c;
is($d->{stack}, array { item 16; item 17; item 18; item 18; end(); }, "cmd_c [16, 17, 18] -> [16, 17, 18, 18]");

diag("Now cmd_v");
$d->cmd_v;
is($d->{stack}, array { item 18; item 18; item 17; item 16; end(); }, "cmd_v [16, 17, 18, 18] -> [18, 18, 17, 16]");

{
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
}

diag("Now cmd_w, cmd_x, cmd_y, cmd_z");


# Finally
done_testing;
