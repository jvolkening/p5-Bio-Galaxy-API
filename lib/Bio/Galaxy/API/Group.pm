package Bio::Galaxy::API::Group;

use strict;
use warnings;
use 5.012;

use Carp;
use Scalar::Util qw/blessed/;

use parent 'Bio::Galaxy::API::Object';

sub base { return 'groups' }
sub required_params { return qw/id name/ }


sub add_user {
    
    my ($self, %args) = @_;

    my $usr = $args{user}
        // croak "Must specify user to add";

    my $usr_id = $usr;

    if ( ref($usr) && blessed($usr) && $usr->isa('Bio::Galaxy::API::User') ) {
        $usr_id = $usr->id;
    }

    croak "Bad user ID or object"
        if ($usr_id =~ /[^a-zA-Z0-9]/);

    my $data = $self->{ua}->_put(
        "groups/$self->{id}/users/$usr_id",
        {},
    ) // return undef;

    return Bio::Galaxy::API::User->new($self->{ua}, $data);

}

sub users {

    my ($self) = @_;

    my $users = $self->{ua}->_get(
        "groups/$self->{id}/users",
    ) // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::User->new($self->{ua}, $_)} @{$users};

}

1;


__END__

=head1 NAME

Bio::Galaxy::API::Group - object representing a Galaxy group


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $group ($ua->groups) {

        # $group is a Bio::Galaxy::API::Group object

        say $group->id;
        say $group->name;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent groups on a Galaxy server. Objects
of this class are not generally created directly but are returned by methods
of the C<Bio::Galaxy::API> class.

=head1 METHODS

=See C<Bio::Galaxy::API::Object> for common methods.

=head2 name

    my $name = $group->name;

Returns the name associated with the group.

=head2 users

    my @users = $group->users();

Returns an array of C<Bio::Galaxy::API::User> objects representing the users
associated with the group.

=head2 add_user

    my $added = $group->add_user( $usr );

Attempts to add an existing user to the group. There is one required
parameter:

=over 1

=item * user - the user to add. This can be either a C<Bio::Galaxy::API::User>
object or an ID string.

=back

Returns a C<Bio::Galaxy::API::User> object representing the user added, or
undefined on failure.

=head2 update

    $group->update();

Queries the server and performs an in-place update of the group metadata
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
