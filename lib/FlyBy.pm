package FlyBy;

use strict;
use warnings;
use 5.010;
our $VERSION = '0.04';

use Moo;

use Carp qw(croak);
use Parse::Lex;
use Scalar::Util qw(reftype);
use Set::Scalar;
use Try::Tiny;

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
    default  => sub { {'AND' => 'intersection', 'OR' => 'union', 'ANDNOT' => 'difference'}; },
);

has query_lexer => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_query_lexer',
);

sub _build_query_lexer {
    my $self = shift;

    my @tokens = (
        "ANDNOT"        => "(and not|AND NOT)",
        "EQUAL"         => "is|IS",
        "AND"           => "and|AND",
        "OR"            => "or|OR",
        "REDUCE"        => "->",
        "COMMA"         => ",",
        "QUOTED_STRING" => qq~(?:\'(?:[^\\\']*(?:\\.[^\\\']*)*)\'|\"(?:[^\\\"]*(?:\\.[^\\\"]*)*)\")~,    # From Text::Balanced
        "ERROR"         => ".*",
        sub { die qq!cannot analyze: "$_[1]"!; });

    return Parse::Lex->new(@tokens);
}

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
            $self->_from_index($k, $v, 1)->insert($rec_index);
        }
    }

    return 1;
}

sub _from_index {
    my ($self, $key, $value, $add_missing_key) = @_;
    my $index_sets = $self->index_sets;

    my $result;

    if (not $add_missing_key and not exists $index_sets->{$key}) {
        $result = Set::Scalar->new;    # Avoiding auto-vi on request
    } else {
        $index_sets->{$key}{$value} //= Set::Scalar->new;    # Sets which do not (yet) exist in the index are null.
        $result = $index_sets->{$key}{$value};
    }

    return $result;
}

sub query {
    my ($self, $query_clauses, $reduce_list) = @_;

    if (not reftype($query_clauses)) {
        my $err; # To let us notice parsing errors;
        # Should be a single query string
        croak 'String queries should have a single parameter' if (defined $reduce_list);
        ($query_clauses, $reduce_list, $err) = $self->parse_query($query_clauses);
        croak $err if $err;
    } else {
        # Should be in our 'raw' datastructure format.
        # Trust the parser above, so we only verify on 'hand-made' queries.
        croak 'Query clauses should be a non-empty array reference.' unless ($query_clauses and (reftype($query_clauses) // '') eq 'ARRAY' and @$query_clauses);
        for my $i (0 .. $#{$query_clauses}) {
            croak 'Improperly specified data structure for query clause ' . $i unless ($self->_check_and_update_clause($query_clauses->[$i], $i));
        }
        croak 'Reduce list should be a non-empty array reference.'
            unless (not $reduce_list or ((reftype($reduce_list) // '') eq 'ARRAY' and scalar @$reduce_list));
    }

    my $start = shift @$query_clauses;    # This one is special, because it defines the initial set.

    my $index_sets = $self->index_sets;
    my $match_set = $self->_from_index($start->[0], $start->[1], 0);

    foreach my $addl_clause (@$query_clauses) {
        my ($method, $key, $value) = @$addl_clause;
        $match_set = $match_set->$method($self->_from_index($key, $value, 0));
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

    return @results;
}

sub parse_query {
    my ($self, $query) = @_;

    my (%values, $err);
    my $lexer = $self->query_lexer;
    my $parse_err = sub { return 'Improper query at: ' . shift; };

    try {
        croak 'Empty query' unless $query;
        my @clause    = ();
        my @tokens    = $lexer->analyze($query);
        my $in_reduce = 0;
        $values{query} = [];
        TOKEN:
        while (my $name = shift @tokens) {
            my $text = shift @tokens;
            # We must be done.
            if ($name eq 'EOI') {
                if (@clause and $in_reduce) {
                    $values{reduce} = [@clause];
                } elsif (@clause) {
                    push @{$values{query}}, [@clause];
                }

                last TOKEN;
            }
            next TOKEN if ($name eq 'COMMA');    # They can put commas anywhere, we don't care.
            my $expected_length = (scalar @{$values{query}}) ? 3 : 2;
            if ($name eq 'QUOTED_STRING') {
                push @clause, substr($text, 1, -1);
            } elsif (my $method = $self->combine_operations->{$name}) {
                croak $parse_err->($text) if ($in_reduce or scalar @clause != $expected_length);
                push @{$values{query}}, [@clause];
                @clause = ($method);             # Starting a new clause.
            } elsif ($name eq 'EQUAL') {
                croak $parse_err->($text) if ($in_reduce or scalar @clause != $expected_length - 1);
            } elsif ($name eq 'REDUCE') {
                croak $parse_err->($text) if ($in_reduce);
                $in_reduce = 1;
                push @{$values{query}}, [@clause] if (@clause);
                @clause = ();
            }
        }
    }
    catch {
        $err = $_;
    };

    return $values{query}, $values{reduce}, $err;
}

sub _check_and_update_clause {
    my ($self, $thing, $pos) = @_;

    my $valid;
    my $whatsit = reftype $thing;
    if ($whatsit and $whatsit eq 'ARRAY') {
        if ($pos == 0) {
            $valid = (scalar @$thing == 2);
        } elsif (scalar @$thing == 3) {
            $thing->[0] = $self->combine_operations->{uc $thing->[0]};    # First entry should be the operation.
            $valid = $thing->[0];
        }
    }

    return $valid;
}

sub all_keys {
    my $self = shift;
    return (sort { $a cmp $b } keys %{$self->index_sets});
}

sub values_for_key {
    my ($self, $key) = @_;
    return (sort { $a cmp $b } keys %{$self->index_sets->{$key}});
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

=over

=item string

  $fb->query("'type' IS 'shark' AND 'food' IS 'seal' -> 'called', 'lives_in'");

The query parameters are joined with `IS` for equality testing.

Multiple clauses are joined with an operation (one of: `AND`,
`OR`, `AND NOT`) to indicate how to combine the results.  Please
note that they are evaluated in the supplied order which is
significant to the results.

The optional reductions are prefaced with `->`.

If no reduction is provided a list of the full record hash
references is returned.
If a reduction list of length 1 is provided, a list of the distinct
values for the matching key is returned.
If a longer reduction list is provided, a list of distinct value
array references (in the provided key order) is returned.

=item raw

  $fb->query([['type' => 'shark'],  ['and', 'food' => 'seal']], ['called', 'lives_in']");

The query clause is supplied as an array reference of array references.

The first query clause is supplied as an array reference with key
and value elements.

Any subsequent clauses are three elements long with a preceding
combine operation.  Valid operations are 'and', 'or', 'andnot'.

A second optional reduction list of strings may be provided which
reduces the result as above.

=back

Will `croak` on improperly supplied query formats.

=item all_keys

Returns an array with all known keys against which one might query.

=item values_for_key

Returns an array of all known values for a given key.

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
