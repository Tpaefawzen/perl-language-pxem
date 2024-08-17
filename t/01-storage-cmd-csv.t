use strict;
use warnings;

use Test2::V0;
use Language::Pxem::DataType;

my $d = Language::Pxem::DataType->new;
$d->Push(16, 17, 18);

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

# Finally
done_testing;
