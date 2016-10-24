[![Build Status](https://travis-ci.org/binary-com/perl-FlyBy.svg?branch=master)](https://travis-ci.org/binary-com/perl-FlyBy)
[![codecov](https://codecov.io/gh/binary-com/perl-FlyBy/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-FlyBy)

# NAME

FlyBy - Ad hoc denormalized querying

# SYNOPSIS

    use FlyBy;

    my $fb = FlyBy->new;
    $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});
    my @array_of_hash_refs = $fb->query({'key' => ['value', 'other value']});

    # Or with a 'reduction list':
    my @array = $fb->query({'key' => 'value'}, ['some key']);
    my @array_of_array_refs = $fb->query({'key' =>'value', 'other key' => 'other value'},
      ['some key', 'some other key']);

# DESCRIPTION

FlyBy is a system to allow for ad hoc querying of data which may not
exist in a traditional datastore at runtime

# USAGE

- add\_records

        $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});

    Supply one or more hash references to be added to the store.

    Keys with undefined values will be silently stripped from each record.  If the
    record is then empty it will be discarded.

    \`croak\` on error; returns \`1\` on success

- query

    - string

            $fb->query("'type' IS 'shark' AND 'food' IS 'seal' -> 'called', 'lives_in'");

        The query parameters are joined with \`IS\` for equality testing, or
        \`IS NOT\` for its inverse.

        Multiple values for a given key can be combined with \`OR\`.

        Multiple keys are joined with AND.

        The optional reductions are prefaced with \`->\`.

        If no reduction is provided a list of the full record hash
        references is returned.
        If a reduction list of length 1 is provided, a list of the distinct
        values for the matching key is returned.
        If a longer reduction list is provided, a list of distinct value
        array references (in the provided key order) is returned.

    - raw

            $fb->query({'type' => 'shark', 'food' => 'seal'}, ['called', 'lives_in']");

        The query clause is supplied as hash reference of keys and values to
        be \`AND\`-ed together for the final result.

        An array reference value is treated as a sucession of 'or'-ed values
        for the provided key.

        All values prepended with an \`!\` are deemed to be a negation of the
        rest of the string as a value.

        A second optional reduction list of strings may be provided which
        reduces the result as above.

    Will \`croak\` on improperly supplied query formats.

- all\_keys

    Returns an array with all known keys against which one might query.

- values\_for\_key

    Returns an array of all known values for a given key.

# CAVEATS

Note that supplied keys may not begin with an \`!\`.  Thought has been
given to making this configurable at creation, but it was deemed to
be unnecessary complexity.

This software is in an early state. The internal representation and
external API are subject to deep breaking change.

This software is not tuned for efficiency.  If it is not being used
to resolve many queries on each instance or if the data is available
from a single canonical source, there are likely better solutions
available in CPAN.

# AUTHOR

Binary.com

# COPYRIGHT

Copyright 2015- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
