# Movable Type (r) (C) 2001-2014 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::DataAPI::Resource::Role::v2;

use strict;
use warnings;

sub updatable_fields {
    [];
}

sub fields {
    [   {   name => 'id',
            type => 'MT::DataAPI::Resource::DataType::Integer',
        },
        qw(
            name
            ),
    ];
}

1;

__END__

=head1 NAME

MT::DataAPI::Resource::Role - Movable Type class for resources definitions of the MT::Role.

=head1 AUTHOR & COPYRIGHT

Please see the I<MT> manpage for author, copyright, and license information.

=cut
