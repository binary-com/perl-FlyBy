package FlyBy;

use strict;
use warnings;
use 5.010;
our $VERSION = '0.01';

use Moo;

use Carp qw(croak);
use Scalar::Util qw(reftype);
use Set::Scalar;

has index_sets => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {}; },
);

has records => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { []; },
);

has combine_operations => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {'and' => 'intersection', 'or' => 'union', 'and not' => 'difference'}; },
);

sub add_records {
    my ($self, @new_records) = @_;

    my $index_sets = $self->index_sets;
    my $records    = $self->records;

    foreach my $record (@new_records) {
        my $whatsit = reftype($record) // 'no reference';
        croak 'Records must be hash references, got: ' . $whatsit unless ($whatsit eq 'HASH');

        my $rec_index = $#$records + 1;    # Even if we accidentally made this sparse, we can insert here.
        $records->[$rec_index] = $record;
        while (my ($k, $v) = each %$record) {
            $self->_from_index($k, $v)->insert($rec_index);
        }
    }

    return 1;
}

sub _from_index {
    my ($self, $key, $value) = @_;
    my $index_sets = $self->index_sets;
    $index_sets->{$key}{$value} //= Set::Scalar->new;    # Sets which do not (yet) exist in the index are null.

    return $index_sets->{$key}{$value};
}

sub query {
    my ($self, $query_clauses, $reduce_list) = @_;

    croak 'Query clauses should be an array reference.' unless ($query_clauses and (reftype($query_clauses) // '') eq 'ARRAY');
    croak 'Reduce list should be a non-empty array reference.'
        unless (not $reduce_list or ((reftype($reduce_list) // '') eq 'ARRAY' and scalar @$reduce_list));

    my $start = shift @$query_clauses;                   # This one is special, because it defines the initial set.
    croak 'Initial query clause must be a bare match' unless ($self->_is_a_query_matcher($start));

    my $index_sets = $self->index_sets;
    my $match_set = $self->_from_index($start->[0], $start->[1]);

    foreach my $addl_clause (@$query_clauses) {
        croak 'Additional query clauses must have a combine operation and match in an array reference' unless ($self->_is_a_clause($addl_clause));
        my ($combine, $key, $value) = @$addl_clause;
        my $method = $self->combine_operations->{$combine};
        $match_set = $match_set->$method($self->_from_index($key, $value));
    }

    my $records = $self->records;
    # Sort may only be important for testing.  Reconsider if large slow sets appear.
    my @indices = sort { $a <=> $b } ($match_set->elements);
    my @results;

    if ($reduce_list) {
        my @keys      = @$reduce_list;
        my $key_count = scalar @keys;
        my %seen;
        foreach my $idx (@indices) {
            my @reduced_element = map { ($records->[$idx]->{$_} // '') } @keys;
            my $seen_key = join('->', @reduced_element);
            if (not $seen{$seen_key}) {
                push @results, ($key_count > 1) ? \@reduced_element : @reduced_element;
                $seen{$seen_key}++;
            }
        }
    } else {
        # They get everything, sort simplifies testing, not sure if I care.
        @results = map { $records->[$_] } @indices;
    }

    return \@results;
}

sub _is_a_clause {
    my ($self, $thing) = @_;

    my $valid;
    my $whatsit = reftype $thing;
    if ($whatsit && $whatsit eq 'ARRAY' && scalar @$thing == 3) {
        $valid = $self->combine_operations->{$thing->[0]};    # First entry should be the operation.
    }

    return $valid;
}

sub _is_a_query_matcher {
    my ($self, $thing) = @_;

    my $whatsit = reftype $thing;

    return $whatsit && $whatsit eq 'ARRAY' && scalar @$thing == 2;
}

1;
__END__

=encoding utf-8

=head1 NAME

FlyBy - Ad hoc denormalized querying

=head1 SYNOPSIS

  use FlyBy;

  my $fb = FlyBy->new;
  $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});
  my $arrayref_of_hashrefs = $fb->query([['key','value'], ['or', 'key', 'other value']]);

  # Or with a 'reduction list':
  my $array_ref = $fb->query([['key','value']], ['field']);
  my $array_ref_of_array_refs = $fb->query([['key','value']], ['field', 'other field']);

=head1 DESCRIPTION

FlyBy is a system to allow for ad hoc querying of data which may not
exist in a traditional datastore at runtime

=head1 USAGE

=over

=item add_records

  $fb->add_records({array => 'of'}, {hash => 'references'}, {with => 'fields'});

Supply one or more hash references to be added to the store.
`croak` on error; returns `1` on success

=item query


  $fb->query([['key','value'], ['and', 'otherkey', 'othervalue']], ['field']);

The first parameter is an array-ref of matching clauses.  The first
one should be a simple match.  The others should tell how to combine
the following match with the previous matches.  The available
combining operations are  `and', `or` and `and not`.

The second parameter is a list of reducing fields which reduces the
result to unique values of the supplied fields.  It also changes the
return value from an array of hash references to an array of array
references (or a simple array of strings, in the single field case.)

Will `croak` on improperly supplied query formats.

=back

=head1 CAVEATS

This software is in an early state. The internal representation and
external API are subject to deep breaking change.

This software is not tuned for efficiency.  If it is not being used
to resolve many queries on each instance or if the data is available
from a single canonical source, there are likely better solutions
available in CPAN.

=head1 AUTHOR

Binary.com

=head1 COPYRIGHT

Copyright 2015- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
