use strict;
use Test::Most;
use Test::FailWarnings;
use FlyBy;

# Some denomarlized data about which we can query.
my %sample_data = (
    bb => {
        type     => 'bear',
        called   => 'black bear',
        food     => 'meat',
        lives_in => 'forest'
    },
    pb => {
        type     => 'bear',
        called   => 'polar bear',
        food     => 'seal',
        lives_in => 'arctic'
    },
    hh => {
        type     => 'shark',
        called   => 'hammerhead',
        food     => 'meat',
        lives_in => 'ocean'
    },
    gw => {
        type     => 'shark',
        called   => 'great white',
        food     => 'seal',
        lives_in => 'ocean'
    },
    bw => {
        type     => 'whale',
        called   => 'blue whale',
        food     => 'kelp',
        lives_in => 'ocean'
    },
);

my $fb = new_ok('FlyBy');

subtest 'load' => sub {
    eq_or_diff($fb->records, [], 'records starts empty');
    eq_or_diff($fb->index_sets, {}, '...and so does the index');
    my @to_load = map { $sample_data{$_} } sort { $a cmp $b } keys %sample_data;
    ok $fb->add_records(@to_load), 'Then we load in the sample data';
    eq_or_diff([@{$fb->records}], [@to_load], '...our records now look just like our sample data');
    cmp_ok(scalar keys %{$fb->index_sets}, '>', 1, '...at least a couple entries in the index');
};

subtest 'query' => sub {
    eq_or_diff($fb->query("'breathes_with' is 'lungs'"), [], 'Querying against a key which does not exist gives an empty set.');
    eq_or_diff($fb->query("'called' IS 'black bear'"), [$sample_data{bb}], 'Querying for a unique key gets just that entry');
    eq_or_diff($fb->query("'lives_in' is 'ocean'"), [map { $sample_data{$_} } qw(bw gw hh)], 'Querying for ocean dwellers gets those 3 entries');
    eq_or_diff($fb->query("'lives_in' is 'ocean' AND 'food' is 'seal'"),
        [$sample_data{gw}], '...but adding in seal-eaters, gets it down to just the one entry');
    eq_or_diff(
        $fb->query("'lives_in' is 'ocean' AND NOT 'food' is 'seal'"),
        [map { $sample_data{$_} } qw(bw hh)],
        '...while dropping the seal-eaters leaves the other two'
    );
    eq_or_diff(
        $fb->query("'lives_in' IS 'ocean' AND 'food' IS 'kelp' OR 'type' IS 'bear'"),
        [map { $sample_data{$_} } qw(bb bw pb)],
        'Ordering of clauses is important'
    );
    eq_or_diff($fb->query("'lives_in' IS 'ocean' OR 'type' IS 'bear' AND 'food' IS 'kelp'"),
        [$sample_data{bw}], '...because they are applied in order against the results');
};

subtest 'query with reduction' => sub {
    eq_or_diff($fb->query("'breathes_with' IS 'lungs' -> 'lives_in'"), [], 'Querying against a key which does not exist gives an empty set.');
    eq_or_diff($fb->query("'type' IS 'bear' -> 'lives_in'"), ['forest', 'arctic'], 'Where do all the bears live?');
    eq_or_diff(
        $fb->query("'food' is 'seal' -> 'type', 'lives_in'"),
        [['shark', 'ocean'], ['bear', 'arctic']],
        'What types of things eat seals and where to they live?'
    );

};

subtest 'keys and values' => sub {
    ;
    eq_or_diff($fb->all_keys, ['called', 'food', 'lives_in', 'type'], 'Proper vaguely introspective list of keys');
    eq_or_diff($fb->values_for_key('type'), ['bear', 'shark', 'whale'], 'Proper vaguely introspective list of values for `type` key');
};

done_testing;
