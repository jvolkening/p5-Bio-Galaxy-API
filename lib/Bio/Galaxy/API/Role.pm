package Bio::Galaxy::API::Role;

use strict;
use warnings;
use 5.012;

use Carp;
use Scalar::Util qw/blessed/;

use parent 'Bio::Galaxy::API::Object';

sub _base { return 'roles' }
sub _required_params { return qw/id name/ }

1;


__END__

=head1 NAME

Bio::Galaxy::API::Role - object representing a Galaxy role


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $role ($ua->roles) {

        # $role is a Bio::Galaxy::API::Role object

        say $role->id;
        say $role->name;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent role on a Galaxy server. Objects
of this class are not generally created directly but are returned by methods
of the C<Bio::Galaxy::API> class.

=head1 METHODS

See C<Bio::Galaxy::API::Object> for common methods.

=head2 name

    my $name = $role->name;

Returns the name associated with the role.

=head2 type

    my $type = $role->type;

Returns the type associated with the role.

=head2 description

    my $description = $role->description;

Returns the description associated with the role.

=head2 update

    $role->update();

Queries the server and performs an in-place update of the role metadata
stored in the object. This is called once upon object creation and generally
will not need to be called again, except possibly in the course of long-running
processes (daemons, etc).

=head1 AUTHOR

Jeremy Volkening, C<< <jdv@base2bio.com> >>

=head1 CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at L<https://github.com/jvolkening/p5-Bio-Galaxy-API>.

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Jeremy Volkening.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
