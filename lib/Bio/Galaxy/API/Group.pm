package Bio::Galaxy::API::Group;

use strict;
use warnings;
use 5.012;

use Carp;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;

our $VERSION = '0.001';


sub new {

    my ($class, $ua, $props) = @_;

    $props->{ua} = $ua;

    for my $required (qw/ua name id/) {
        croak "Required parameter $required missing"
            if (! defined $props->{$required});
    }

    my $self =  bless $props => $class;

    $self->update();

    return $self;

}

sub id      {return $_[0]->{id}      }
sub name    {return $_[0]->{name}    }

sub add_user {
    
    my ($self, $usr) = @_;

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

sub update {
    
    my ($self) = @_;

    my $ref = $self->{ua}->_get(
        "groups/$self->{id}",
    );

    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

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

=head2 id

    my $id = $group->id;

Returns the group ID.

=head2 name

    my $name = $group->name;

Returns the name associated with the group.

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
