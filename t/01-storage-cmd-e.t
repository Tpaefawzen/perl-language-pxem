use strict;
use warnings;

use Test2::V0;
use Language::Pxem::DataType;

my $d = Language::Pxem::DataType->new;
$d->Push(16, 17, 18);
$d->{register} = 132;

my $forked = $d->cmd_e;
$d->cmd_s;

is($forked->{stack}, array { item 16; item 17; item 18; end() }, "cmd_e [16,17,18] forks itself as deep copy");
is($forked->{register}, U(), "cmd_e register undef");

done_testing;
