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

has connectors => (
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
    my ($self, $clauses) = @_;

    croak 'Query clauses should be an array reference.' unless ($clauses and (reftype($clauses) // '') eq 'ARRAY');

    my $start = shift @$clauses;                         # This one is special, because it defines the initial set.
    croak 'Initial query clause must be a bare match' unless ($self->_is_a_query_matcher($start));

    my $index_sets = $self->index_sets;
    my $match_set = $self->_from_index($start->[0], $start->[1]);

    foreach my $addl_clause (@$clauses) {
        croak 'Additional query clauses must have a connector and match in an array reference' unless ($self->_is_a_clause($addl_clause));
        my ($connector, $key, $value) = @$addl_clause;
        my $method = $self->connectors->{$connector};
        $match_set = $match_set->$method($self->_from_index($key, $value));
    }

    my $records = $self->records;

    return [map { $records->[$_] } sort { $a <=> $b } ($match_set->elements)];
}

sub _is_a_clause {
    my ($self, $thing) = @_;

    my $valid;
    my $whatsit = reftype $thing;
    if ($whatsit && $whatsit eq 'ARRAY' && scalar @$thing == 3) {
        $valid = $self->connectors->{$thing->[0]};    # First entry should be the operation.
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

FlyBy - Ad-hoc denormalized querying

=head1 SYNOPSIS

  use FlyBy;

=head1 DESCRIPTION

FlyBy is a system to allow for adhoc querying of data which may not
exist in a traditional datastore at runtime

=head1 AUTHOR

Binary.com

=head1 COPYRIGHT

Copyright 2015- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
