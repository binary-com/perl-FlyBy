package FlyBy;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Moo;

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
