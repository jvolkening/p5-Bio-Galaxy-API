package Bio::Galaxy::API::Workflow::Invocation;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;

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

    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

}

sub jobs {

    my ($self) = @_;

    $self->update;

    return
        map  {$_->[1]}
        sort {$a->[0] <=> $b->[0]}
        map  {[$_->{order_index}, $_->{job_id} // 'NA']}
        @{ $self->{steps} };

}

sub states {

    my ($self) = @_;

    $self->update;

    return
        map  {$_->[1]}
        sort {$a->[0] <=> $b->[0]}
        map  {[$_->{order_index}, $_->{state} // 'NA']}
        @{ $self->{steps} };

}

1;


__END__

=head1 NAME

Bio::Galaxy::API::Workflow::Invocation - object representing a Galaxy workflow
run

=head1 SYNOPSIS

    # assuming $workflow is a Bio::Galaxy::API::Workflow object

    my $run = $workflow->run( @args );

    # $run is now a Bio::Galaxy::API::Workflow::Invocation object

=head1 DESCRIPTION

This class is used to represent an invocation (i.e. "run") of a Galaxy
workflow. Objects of this class are not generally created directly but are
returned by methods of the C<Bio::Galaxy::API::Workflow> class.

=head1 METHODS

=head2 id

    my $id = $invocation->id;

Returns the invocation ID.

=head2 update

    $invocation->update();

Queries the server and performs and in-place update of the invocation metadata
stored in the object. This can be used to check the status of the run, etc.

=head2 jobs

    my @job_ids = $invocation->jobs();

Returns a list of job IDs associated with the invocation.

=head2 states

    my @states = $invocation->states();

Returns a list of job state strings associated with the invocation.

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
