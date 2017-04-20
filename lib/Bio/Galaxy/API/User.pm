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

    return $self;

}

sub id      {return $_[0]->{id}      }
sub email   {return $_[0]->{email}   }
sub deleted {return $_[0]->{deleted} }

sub get_key {

    my ($self) = @_;

    return $self->{ua}->_post("users/$self->{id}/api_key", {user_id => $self->{id}});

}

sub description {
    
    my ($self) = @_;

    my $description = $self->{ua}->_get("users/$self->{id}");

    return $description;

}

1;
