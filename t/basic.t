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

subtest 'query parameters' => sub {

    my $default = new_ok('FlyBy');
    throws_ok { $default->query() } qr/array reference/, 'Query needs some clauses';
    throws_ok { $default->query('a', 'b') } qr/array reference/, '...given as an array reference';
    throws_ok { $default->query([]) } qr/a bare match/, '...a non-empty array reference';
    throws_ok { $default->query(['a', 'b', 'c']) } qr/a bare match/, '...with the first clause as a bare match.';
    ok $default->query([['a', 'b']]), '...perhaps like this.';
    throws_ok { $default->query([['a', 'b'], ['c', 'd']]) } qr/combine operation and match/,
        'More complex queries need combine operation and match for additional clauses';
    throws_ok { $default->query([['a', 'b'], ['combine operation', 'c', 'd']]) } qr/combine operation and match/,
        '...which includes a valid combine operation as the first term';
    ok $default->query([['a', 'b'], ['or', 'c', 'd']]), '...something like this.';
    throws_ok { $default->query([['a', 'b'], ['or', 'c', 'd']], 'a') } qr/non-empty array/, 'Queries with reductions shoould have an array ref';
    throws_ok { $default->query([['a', 'b'], ['or', 'c', 'd']], []) } qr/non-empty array/, '...a non-empty array ref';
    ok $default->query([['a', 'b'], ['or', 'c', 'd']], ['a']), '...a bit like this, maybe.';
};

done_testing;
