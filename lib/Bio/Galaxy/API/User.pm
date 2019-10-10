package Bio::Galaxy::API::User;

use strict;
use warnings;
use 5.012;

use Carp;
use List::Util qw/first/;

use parent 'Bio::Galaxy::API::Object';

sub _base { return 'users' }
sub _required_params { return qw/id email/ }

sub private_role {

    my ($self) = @_;

    my @roles = $self->{ua}->roles;

    my @r = grep {
           $_->name eq $self->email
        && $_->type eq 'private'
    } @roles;

    if (scalar @r != 1) {
        # This is expected to always be defined, and thus should throw a fatal
        # error if missing
        die "ERROR: Failed to located unique private role for user $self";
    }

    return $r[0];

}


sub key {

    my ($self) = @_;

    my $ref = $self->{ua}->_get(
        "users/$self->{id}/api_key/inputs",
    );

    my $key_ref = first {$_->{name} eq 'api-key'}
        @{ $ref->{inputs} };
    return defined $key_ref
        ? $key_ref->{value}
        : undef;

}

1;


__END__

=head1 NAME

Bio::Galaxy::API::User - object representing a Galaxy user


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $user ($ua->users) {

        # $user is a Bio::Galaxy::API::User object

        say $user->id;
        say $user->email;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent individual users on a Galaxy server. Objects
of this class are not generally created directly but are returned by methods
of the C<Bio::Galaxy::API> class.

=head1 METHODS

See C<Bio::Galaxy::API::Object> for common methods.

=head2 email

    my $email = $user->email;

Returns the email address associated with the user.

=head2 deleted

    my $is_deleted = $user->deleted;

Returns a boolean value indicating whether the user has been deleted on the
system (note that for Galaxy, users are only marked "deleted" and never
removed completely from the database).

=head2 key

    my $api_key = $user->key;

Returns the API key of the user. Note that this is not necessarily the same as
that used for the current session, which may be transacted under a different
user if that user is an admin.

=head2 private_role

    my $role = $user->private_role;

Returns the private role of the user as a L<Bio::Galaxy::API::Role> object.
This role is needed for some operations such as setting library permissions.
Note that it is currently matched based on email address of the user -- this
is not a documented behavior but appears to be how the user/role link is
maintained.

=head1 AUTHOR

Jeremy Volkening, C<< <jdv@base2bio.com> >>

=head1 CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at L<https://github.com/jvolkening/p5-Bio-Galaxy-API>.

=head1 COPYRIGHT AND LICENSE

Copyright 2017-2018 Jeremy Volkening.

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
