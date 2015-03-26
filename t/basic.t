use strict;
use Test::Most;
use Test::FailWarnings;
use FlyBy;

subtest 'instantiation' => sub {

    my $default = new_ok('FlyBy');
    is(ref $default->records, ref [], 'records is an array ref');
    is(ref $default->index_sets, ref {}, 'records is a hash ref');

};

subtest 'add_records' => sub {

    my $default = new_ok('FlyBy');
    throws_ok { $default->add_records('not', 'like', 'this') } qr/hash references, got: no reference/, 'Cannot add a plain array';
    throws_ok { $default->add_records(['nor', 'like', 'this']) } qr/hash references, got: ARRAY/, '... nor an array reference';
    ok $default->add_records({'but' => 'like this'}, {'and' => 'this'}), '... but looking like a hash-ref or more is fine.';

};

subtest 'query syntax' => sub {

    my $default = new_ok('FlyBy');
    throws_ok { $default->query() } qr/Empty/, 'Query needs some clauses';
    throws_ok { $default->query("'a' IS 'b' AND 'c' ISNT 'd'") } qr/can't analyze/, 'ISNT does not exist';
};

done_testing;
