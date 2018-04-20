package Bio::Galaxy::API::Library;

use strict;
use warnings;
use 5.012;

use File::Basename qw/basename/;
use List::Util qw/first/;
use Data::Dumper;
use Carp;

use Bio::Galaxy::API::Library::Item;

use parent 'Bio::Galaxy::API::Object';

sub base { return 'libraries' }
sub required_params { return qw/id/ }

sub root    { return $_[0]->{root_folder_id} }

sub contents {
    
    my ($self) = @_;

    my $contents = $self->{ua}->_get("libraries/$self->{id}/contents");

    return
        grep {! $_->deleted()}
        map  { Bio::Galaxy::API::Library::Item->new(
            $self->{id},
            $self->{ua},
            $_,
        ) } @{$contents};

}

sub _update_tree {

    my ($self) = @_;

    my $tree = {};
    my %children = ();

    for my $item ( $self->contents ) {

        my $id = $item->{id};
        $tree->{$id} = $item;
        my $parent = $item->{type} eq 'file'
            ? $item->{folder_id}
            : $item->{parent_id};
        $tree->{$id}->{_parent} = $parent;
        if (defined $parent) {
            push @{ $children{$parent} }, $id;
        }
        $tree->{$id}->{_children} //= [];

    }

    for my $id (keys %children) {
        $tree->{$id}->{_children} = $children{$id};
    }

    $self->{tree} = $tree;

}

sub get_item {

    my ($self, %args) = @_;

    my $leaf = $args{parent} // $self->root;
    my $path = $args{path}   // croak "Must supply 'path' argument";

    $path =~ s/\\/\//g;
    $path =~ s/^\///g;

    $self->_update_tree;

    croak "parent $leaf not found in library"
        if (! defined $self->{tree}->{$leaf});

    my @parts = grep {length $_} split /\//, $path;
    croak "Given path empty" if (! scalar @parts);

    my $item;

    PART:
    while (@parts) {

        my $item = $parts[0];

        my $existing = first {
               $self->{tree}->{$_}->{name} eq $item
          && ! $self->{tree}->{$_}->{deleted}
        } @{ $self->{tree}->{$leaf}->{_children} };

        return undef if (! defined $existing);

        $leaf = $existing;
        shift @parts;

    }

    # leaf should now contain ID of requested item

    my $res = $self->{ua}->_get("libraries/$self->{id}/contents/$leaf");
    return undef if (! defined $res);

    return Bio::Galaxy::API::Library::Item->new(
        $self->{id},
        $self->{ua},
        $res,
    );

}

sub _add_item {

    my ($self, $type, $path, $parent, $fn, $ftype) = @_;

    my $payload = {
        create_type => $type,
    };

    $parent //= $self->root;

    $path =~ s/\\/\//g;
    $path =~ s/^\///g;

    my @parts = grep {length $_} split /\//, $path;
    croak "Given path empty" if (! scalar @parts);

    my $name = pop @parts;

    my @contents = $self->contents;

    # strip existing parts of path
    FOLDER:
    while (@parts) {

        my $folder = $parts[0];
    
        my $existing = first {
          ! $_->{deleted}          &&
            $_->{type} eq 'folder' &&
            $_->{name} eq $folder  &&
            $_->{parent_id} eq $parent
        } @contents;

        if (defined $existing) {
            $parent = $existing->id;
            shift @parts;
            next FOLDER;
        }

        last FOLDER;

    }

    # create remaining parts of path
    for my $folder (@parts) {

        my $leaf = $self->_add_item(
            'folder',
            $folder,
            $parent,
        );
        $parent = $leaf->id;

    } 

    $payload->{name}      = $name;
    $payload->{folder_id} = $parent;

    if (defined $fn) {
        $payload->{upload_option} = 'upload_file';
        $payload->{file_type}     = $ftype // 'auto';
    }

    # check for existing (this library doesn't allow duplicate names
    # even though Galaxy does)

    my $parent_field
        = $type eq 'folder' ? 'parent_id'
        : $type eq 'file'   ? 'folder_id'
        : croak "Bad type ($type\n";
    my $existing = first {
      ! $_->{deleted}       &&
        $_->{type} eq $type &&
        $_->{name} eq $name &&
        $_->{$parent_field} eq $parent
    } $self->contents;

    if (defined $existing) {

        # for folders, user shouldn't care whether it existed or was created
        # new as long as as we return the leaf node to them
        if ($type eq 'folder') {
            return $existing;
        }

        # for files, we should return some indication that no new file was
        # created
        else {
            say STDERR "file exists!!!!";
            print Dumper $existing;
            return 0;
        }
    }

    my $res = $self->{ua}->_post(
        "libraries/$self->{id}/contents",
        $payload,
        $fn,
    );

    return undef if (! defined $res);
    $res = $res->[0];

    $res->{type} = $type;

    return Bio::Galaxy::API::Library::Item->new(
        $self->{id},
        $self->{ua},
        $res,
    );

}

sub add_folder {

    my ($self, %args) = @_;

    croak "Must supply 'path' argument to add_folder()"
        if (! defined $args{path});

    return $self->_add_item(
        'folder',
        $args{path},
        $args{parent},
    );

}

sub add_file {

    my ($self, %args) = @_;

    croak "Must supply 'file' argument to add_file()"
        if (! defined $args{file});
    croak "Local file not found or not readable"
        if (! -r $args{file});

    $args{path} //= basename($args{file});

    return $self->_add_item(
        'file',
        $args{path},
        $args{parent},
        $args{file},
        $args{file_type},
    );

}

sub delete_item {

    my ($self, $item_id) = @_;

    my $ret = $self->{ua}->_delete(
        "libraries/$self->{id}/contents/$item_id",
    );

    croak "Failed to delete item $item_id from library $self->{id}"
        if (! $ret || ! $ret->{deleted});

    return;

}

sub set_permissions {

    my ($self, %args) = @_;

    my $payload = {action => 'set_permissions'};
    
    for (qw/
        access_ids
        add_ids
        manage_ids
        modify_ids
    /) {
        next if (! defined $args{$_});
        $payload->{"$_\[\]"} = $args{$_};
    }

    my $data = $self->{ua}->_post(
        "libraries/$self->{id}/permissions",
        $payload,
    ) // return undef;

    return 1;

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

See C<Bio::Galaxy::API::Object> for common methods.

=head2 name

    my $name = $lib->name;

Returns the name associated with the library (note that this value is not
necessarily unique).

=head2 description

    my $desc = $lib->description;

Returns the description associated with the library.

=head2 synopsis

    my $name = $lib->synopsis;

Returns the synopsis associated with the library.

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
        path   => 'some/path/structure',
        parent => $parent_id,
    );

Add a folder to the library, building up the path given as necessary (i.e. if
'path' is given as 'foo/bar/baz', it will create each directory sequentially
if they don't already exist). Takes two possible parameters:

=over 1

=item * path - (required) a path specification to create in the library

=item * parent - the ID of the parent folder under which to create the new
folder/path (if not given, defaults to the root of the library)

=back

=head2 add_file

    my $item = $lib->add_file(
        parent    => $parent_id,
        path      => $name,
        file      => $local_fn,
        file_type => $ftype,
    );

Upload a file to the library, building up the path given as necessary (i.e. if
'path' is given as 'foo/bar/baz.txt', it will create each directory
sequentially if they don't already exist before uploading the actual file).
Takes four possible parameters:

=over 1

=item * file - (required) path to local file to upload

=item * path - a path specification to create in the library (if not given,
defaults to the basename of the file)

=item * parent - the ID of the parent folder under which to create the new
folder/path (if not given, defaults to the root of the library)

=item * file_type - the data type of the file to pass to Galaxy (if not given,
Galaxy will try to guess)

=back

=head2 delete_item

    my $success = $lib->delete_item( $item_id );

Deletes an item from the library, returning true on success and false on
failure.

=head2 set_permissions

    my $success = $lib->set_permissions(
        access_ids => $ids_ref,
        add_ids    => $ids_ref,
        manage_ids => $ids_ref,
        modify_ids => $ids_ref,
    );

Sets permissions on the library, returning true on success and false on
failure. There are four parameters, all optional, each defining the roles to
be associated with that permission type. Each parameter takes an array ref of
role IDs (user, group, etc). Parameters that are not defined will be
unchanged. To remove all restrictions on a permission type, pass in an empty
reference.

=over 1

=item * access_ids - (optional) array reference of role IDs

=item * add_ids - (optional) array reference of role IDs

=item * manage_ids - (optional) array reference of role IDs

=item * modify_ids - (optional) array reference of role IDs

=back

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
