package Bio::Galaxy::API::User;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;
use Data::Dumper;

our $VERSION = '0.001';

#'model_class' => 'StoredWorkflow',
#'id' => 'f2db41e1fa331b3e',
#'published' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
#'deleted' => $VAR1->{'published'},
#'url' => '/api/workflows/f2db41e1fa331b3e',
#'tags' => [],
#'name' => 'test workflow',
#'latest_workflow_uuid' => 'd64c9515-83dc-4505-a842-a32be5c31321',
#'owner' => 'foo_bar'

#use Bio::Galaxy::API::User::Invocation;

sub new {

    my ($class, $ua, $props) = @_;

    $props->{ua} = $ua;

    for my $required (qw/ua email id/) {
        croak "Required parameter $required missing"
            if (! defined $props->{$required});
    }

    my $self =  bless $props => $class;

    $self->update();

    return $self;

}

sub id      {return $_[0]->{id}      }
sub email   {return $_[0]->{email}   }
sub deleted {return $_[0]->{deleted} }

sub new_key {

    my ($self) = @_;

    return $self->{ua}->_post(
        "users/$self->{id}/api_key",
        {
            user_id => $self->{id},
        },
    );

}

sub update {
    
    my ($self) = @_;

    my $ref = $self->{ua}->_get(
        "users/$self->{id}",
    );

    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

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

=head2 id

    my $id = $user->id;

Returns the user ID.

=head2 email

    my $email = $user->email;

Returns the email address associated with the user.

=head2 deleted

    my $is_deleted = $user->deleted;

Returns a boolean value indicating whether the user has been deleted on the
system (note that for Galaxy, users are only marked "deleted" and never
removed completely from the database).

=head2 new_key

    my $api_key = $user->new_key();

Returns a new API key for the user. IMPORTANT: this process is destructive,
meaning that the new API key will replace the previous one. If you call this
on the user currently authenticated for the session, you will need to call the
C<api_key> method on your C<Bio::Galaxy::API> client object using the new key
or subsequent server interactions will fail.

=head2 update

    $user->update();

Queries the server and performs and in-place update of the user metadata
stored in the object. This is called once upon object creation and generally
will not need to be called again except possibly in the course of long-running
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
