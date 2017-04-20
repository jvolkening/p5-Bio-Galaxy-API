package Bio::Galaxy::API::Workflow::Invocation;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;
use Data::Dumper;

our $VERSION = '0.001';

sub new {

    my ($class, $ua, $props) = @_;

    $props->{ua} = $ua;

    for my $required (qw/ua id state history update_time workflow_id/) {
        croak "Required parameter $required missing"
            if (! defined $props->{$required});
    }

    my $self =  bless $props => $class;

    return $self;

}

sub id      {return $_[0]->{id}     }

sub update {

    my ($self) = @_;

    my $ref = $self->{ua}->_get(
        "workflows/$self->{workflow_id}/invocations/$self->{id}",
    );
    print Dumper $ref;
    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

}

1;
