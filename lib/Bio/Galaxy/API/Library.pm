package Bio::Galaxy::API::Library;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;
use Data::Dumper;

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

sub add_item {

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

    return $self->add_item( $leaf, $name, 'folder' );

}

sub add_file {

    my ($self, $leaf, $name, $fn_local) = @_;

    return $self->add_item( $leaf, $name, 'file', $fn_local );

}
    
1;
