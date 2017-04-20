package Bio::Galaxy::API::Library;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;

use Bio::Galaxy::API::Library::Item;

#'synopsis' => 'This is the personal data library for Baz Bar',
#'id' => 'ebfb8f50c6abde6d',
#'create_time_pretty' => '',
#'can_user_modify' => $VAR1->[0]{'deleted'},
#'description' => 'Baz Bar\'s library',
#'model_class' => 'Library',
#'create_time' => '2017-04-15T01:54:59.147361',
#'name' => 'baz@bar.net',
#'deleted' => $VAR1->[1]{'deleted'},
#'root_folder_id' => 'Febfb8f50c6abde6d',
#'can_user_add' => $VAR1->[0]{'deleted'},
#'can_user_manage' => $VAR1->[0]{'deleted'}

our $VERSION = '0.001';

sub new {

    my ($class, $ua, $props) = @_;

    $props->{ua} = $ua;

    for my $required (qw/ua name id/) {
        croak "Required parameter $required missing"
            if (! defined $props->{$required});
    }

    my $self =  bless $props => $class;

    return $self;

}

sub id      {return $_[0]->{id}     }
sub name    {return $_[0]->{name}   }
sub deleted {return $_[0]->{deleted}}

sub contents {
    
    my ($self) = @_;

    my $contents = $self->{ua}->_get("libraries/$self->{id}/contents");

    return
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::Library::Item->new($self->{ua}, $_)} @{$contents};

}

sub _add_item {

    my ($self, $leaf, $name, $type, $fn) = @_;

    my $payload = {
        folder_id   => $leaf,
        create_type => $type,
    };

    if (defined $fn) {
        $payload->{upload_option}    = 'upload_file';
        #$payload->{filesystem_paths} = $fn;
        $payload->{file_type} = 'auto';
    }
    else {
        $payload->{name} = $name;
    }

    my $res = $self->{ua}->_post(
        "libraries/$self->{id}/contents",
        $payload,
        $fn,
    );

    return undef if (! defined $res);
    $res = $res->[0];

    $res->{type} = $type;

    return Bio::Galaxy::API::Library::Item->new($self->{ua}, $res);

}

sub add_folder {

    my ($self, $leaf, $name) = @_;

    return $self->_add_item( $leaf, $name, 'folder' );

}

sub add_file {

    my ($self, $leaf, $name, $fn_local) = @_;

    return $self->_add_item( $leaf, $name, 'file', $fn_local );

}
    
1;


__END__

=head1 NAME

Bio::Galaxy::API::Library - object representing a Galaxy data library


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $lib ($ua->libraries) {

        # $lib is a Bio::Galaxy::API::Library object

        say $lib->id;
        say $lib->name;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent individual data libraries on a Galaxy server.
Objects of this class are not generally created directly but are returned by
methods of the C<Bio::Galaxy::API> class.

=head1 METHODS

=head2 id

    my $id = $lib->id;

Returns the library ID.

=head2 name

    my $name = $lib->name;

Returns the name associated with the library (note that this value is not
necessarily unique).

=head2 deleted

    my $is_deleted = $lib->deleted;

Returns a boolean value indicating whether the library has been marked as
deleted on the system.

=head2 contents

    my @items = $lib->contents;

Returns an array of <Bio::Galaxy::API::Library::Item> objects, one per
subfolder or file within the library.

=head2 add_folder

    my $item = $lib->add_folder(
        $parent_id,
        $name,
    );

Takes two arguments (the ID of the parent folder and a name for the new
folder) and add a folder to the library hierarchy at that location. Returns a
C<Bio::Galaxy::API::Library::Item> object representing the new folder, or
undef if the call failed (for instance, for an invalid parent ID).

=head2 add_file

    my $item = $lib->add_file(
        $parent_id,
        $name,
        $local_fn,
    );

Takes three arguments (the ID of the parent folder, a name for the new file,
and the path to the local file on disk) and uploads the file to the library
hierarchy at that location. Returns a C<Bio::Galaxy::API::Library::Item>
object representing the new file, or undef if the call failed (for instance,
for an invalid parent ID).

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
