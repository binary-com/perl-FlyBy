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

subtest 'string query syntax' => sub {

    my $default = new_ok('FlyBy');
    throws_ok { $default->query() } qr/Empty/, 'Query needs some clauses';
    throws_ok { $default->query("'a' IS 'b' AND 'c' ISNT 'd'") } qr/cannot analyze/, 'ISNT does not exist';
    throws_ok { $default->query('a', 'b') } qr/single parameter/, 'Only a single string, not an array of them';
};

subtest 'raw query parameters' => sub {

    my $default = new_ok('FlyBy');
    throws_ok { $default->query([]) } qr/non-empty array/, 'Raw query starts with a non-empty array reference';
    throws_ok { $default->query(['a', 'b' => 'c']) } qr/clause 0/, '...with the first clause as a bare match.';
    lives_ok { $default->query([['a' => 'b']]) } '...perhaps like this.';
    throws_ok { $default->query([['a' => 'b'], ['c' => 'd']]) } qr/clause 1/,
        'More complex queries need combine operation and match for additional clauses';
    throws_ok { $default->query([['a' => 'b'], ['combine operation', 'c' => 'd']]) } qr/clause 1/,
        '...which includes a valid combine operation as the first term';
    lives_ok { $default->query([['a' => 'b'], ['or', 'c' => 'd']]) } '...something like this.';
    throws_ok { $default->query([['a' => 'b'], ['or', 'c' => 'd']], 'a') } qr/non-empty array/, 'Queries with reductions shoould have an array ref';
    throws_ok { $default->query([['a' => 'b'], ['or', 'c' => 'd']], []) } qr/non-empty array/, '...a non-empty array ref';
    lives_ok {
        $default->query([['a' => 'b'], ['or', 'c' => 'd']], ['a'])
    }
    '...a bit like this, maybe.';
};

done_testing;
