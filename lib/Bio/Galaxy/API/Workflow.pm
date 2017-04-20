package Bio::Galaxy::API::Workflow;

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

use Bio::Galaxy::API::Workflow::Invocation;

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

sub description {
    
    my ($self) = @_;

    my $description = $self->{ua}->_get("workflows/$self->{id}");

    return $description;

}

sub run {

    my ($self, %args) = @_;

    # parameters
    # ds_map
    # history

    for my $required (qw/ds_map/) {
        croak "Required parameter $required missing"
            if (! defined $args{$required});
    }

    my $payload = {
        workflow_id => $self->id(),
        ds_map      => $args{ds_map},
    };

    for my $optional (qw/history parameters/) {
        $payload->{$optional} = $args{$optional}
            if (defined $args{$optional});
    }

    my $inv = $self->{ua}->_post( 'workflows', $payload );
    return $inv if (! defined $inv);
    return Bio::Galaxy::API::Workflow::Invocation->new( $self->{ua}, $inv );

}
    
1;
