use strict;
use Test::Most;
use Test::FailWarnings;
use FlyBy;

subtest 'instantiation' => sub {

    my $default = new_ok('FlyBy');
    is(ref $default->records, ref [], 'records is an array ref');
    is(ref $default->index_sets, ref {}, 'records is a hash ref');

};

done_testing;
