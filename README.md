# NAME

FlyBy - Ad hoc denormalized querying

# SYNOPSIS

    use FlyBy;

    my $fb = FlyBy->new;
    $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});
    my $arrayref_of_hashrefs = $fb->query([['key','value'], ['or', 'key', 'other value']]);

    # Or with a 'reduction list':
    my $array_ref = $fb->query([['key','value']], ['field']);
    my $array_ref_of_array_refs = $fb->query([['key','value']], ['field', 'other field']);

# DESCRIPTION

FlyBy is a system to allow for ad hoc querying of data which may not
exist in a traditional datastore at runtime

# USAGE

- add\_records

        $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});

    Supply one or more hash references to be added to the store.
    \`croak\` on error; returns \`1\` on success

- query

        $fb->query([['key','value'], ['and', 'otherkey', 'othervalue']], ['field']);

    The first parameter is an array-ref of matching clauses.  The first
    one should be a simple match.  The others should tell how to combine
    the following match with the previous matches.  The available
    combining operations are  \`and', \`or\` and \`and not\`.

    The second parameter is a list of reducing fields which reduces the
    result to unique values of the supplied fields.  It also changes the
    return value from an array of hash references to an array of array
    references (or a simple array of strings, in the single field case.)

    Will \`croak\` on improperly supplied query formats.

# CAVEATS

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
