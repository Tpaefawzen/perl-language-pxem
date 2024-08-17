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

done_testing;
