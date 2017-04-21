package Bio::Galaxy::API::Library::Item;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;

our $VERSION = '0.001';

sub new {

    my ($class, $lib, $ua, $props) = @_;

    $props->{ua}      = $ua;
    $props->{library} = $lib;

    for my $required (qw/ua library name id/) {
        croak "Required parameter $required missing"
            if (! defined $props->{$required});
    }

    my $self =  bless $props => $class;

    $self->update;

    return $self;

}

sub id      {return $_[0]->{id}     }
sub name    {return $_[0]->{name}   }
sub deleted {return $_[0]->{deleted}}

sub update {
    
    my ($self) = @_;

    my $ref = $self->{ua}->_get(
        "libraries/$self->{library}/contents/$self->{id}",
    );

    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

}

1;


__END__

=head1 NAME

Bio::Galaxy::API::Library::Item - object representing a Galaxy data library
item


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $lib ($ua->libraries) {

        for my $item ($lib->contents) {

            # $lib is a Bio::Galaxy::API::Library::Item object

            say $lib->id;
            say $lib->name;

            #etc

        }

    }

=head1 DESCRIPTION

This class is used to represent individual data library items (folders and
files) on a Galaxy server. Objects of this class are not generally created
directly but are returned by methods of the C<Bio::Galaxy::API::Library> class.

=head1 METHODS

=head2 id

    my $id = $item->id;

Returns the item ID.

=head2 name

    my $name = $item->name;

Returns the name associated with the item (note that this value is not
necessarily unique).

=head2 deleted

    my $is_deleted = $item->deleted;

Returns a boolean value indicating whether the library item has been marked as
deleted on the system.

=head2 update

    $item->update();

Queries the server and performs an in-place update of the item metadata
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
