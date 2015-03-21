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

sub add_records {
    my ($self, @new_records) = @_;

    my $index_sets = $self->index_sets;
    my $records    = $self->records;

    foreach my $record (@new_records) {
        my $whatsit = reftype $record // 'no reference';
        croak 'Records must be hash references, got: ' . $whatsit unless ($whatsit eq 'HASH');

        my $rec_index = $#$records + 1;    # Even if we accidentally made this sparse, we can insert here.
        $records->[$rec_index] = $record;
        foreach my $key (keys %$record) {
            $index_sets->{$key}{$record->{$key}} //= Set::Scalar->new;
            $index_sets->{$key}{$record->{$key}}->insert($rec_index);
        }
    }
    return 1;
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
