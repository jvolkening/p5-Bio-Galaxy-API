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

    $self->update();

    return $self;

}

sub id      {return $_[0]->{id}     }
sub name    {return $_[0]->{name}   }
sub deleted {return $_[0]->{deleted}}

sub update {
    
    my ($self) = @_;

    my $ref = $self->{ua}->_get(
        "workflows/$self->{id}",
    );

    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

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


__END__

=head1 NAME

Bio::Galaxy::API::Workflow - object representing a Galaxy workflow


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $workflow ($ua->workflows) {

        # $workflow is a Bio::Galaxy::API::Workflow object

        say $workflow->id;
        say $workflow->name;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent individual users on a Galaxy server. Objects
of this class are not generally created directly but are returned by methods
of the C<Bio::Galaxy::API> class.

=head1 METHODS

=head2 id

    my $id = $workflow->id;

Returns the workflow ID.

=head2 name

    my $name = $workflow->name;

Returns the name associated with the workflow. Note that this value is not
necessarily unique.

=head2 deleted

    my $is_deleted = $workflow->deleted;

Returns a boolean value indicating whether the workflow has been marked
deleted in the Galaxy database.

=head2 run

    my $invocation = $workflow->run(
        ds_map => {
            $input_1_id => {
                id => $dataset_id_1,
                src => $input_src,
            }
            $input_2_id => {
                id => $dataset_id_2,
                src => $input_src,
            }
        },
        history => 'A test history',

Runs the workflow on a given set of inputs and returns a
C<Bio::Galaxy::API::Workflow::Invocation> object representing the current run.
Accepts the following parameters:

=over 1

=item * ds_map - (required) reference to a data structure describing the input files to
use. Each key should be the ID of the input (currently needs to be found
manually by applying Data::Dumper, etc, to this object) and the value another
hash reference with the following keys:

=over 1

=item * id - the dataset ID

=item * src - the dataset source, one of [ldda|ld|hda]

=back

=item * history - the name of a new history to create contanining the run. If
not given, a generic history name will be used.

=back

=head2 update

    $workflow->update();

Queries the server and performs and in-place update of the workflow metadata
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
