package API::Galaxy;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use URI;
use HTTP::Tiny;
use Carp;
use JSON;
use URI::Escape;

use API::Galaxy::Library;

our $VERSION = '0.001';

sub new {

    my ($class, %args) = @_;

    # set defaults where appropriate
    my $self = bless {
        check_secure => 1,
        retry        => 3,
    } => $class;

    for my $required (qw/url/) {
        croak "Required parameter $required missing"
            if (! defined $args{$required});
    }

    # handle simple pass-through values
    $self->{check_secure} = $args{check_secure}
        if (defined $args{check_secure});

    # validate URL
    my $url = URI->new( $args{url} );
    croak "Unrecognized URL scheme (please use e.g. \"https://server.org\")"
        if (! $url->has_recognized_scheme);
    croak "Insecure URL (set 'check_secure => 0' if you really want to do this"
        if (! $url->secure && $self->{check_secure});
    # set default base path if missing
    $url->path('api') if (! length $url->path);

    $self->{url} = $url;
    $self->{ua} = HTTP::Tiny->new;

    # check connectivity
    my $version = $self->version;
    croak "Attempt to test API connection failed"
        if (! defined $version);

    # attempt to parse or find API key (otherwise it will be undefined and the
    # functionality will be limited to non-account interfaces such as server
    # version, etc
    if (defined $args{api_key}) {
        $self->{key} = $args{api_key};
    }
    elsif (-r "$ENV{HOME}/.galaxy_api_key") {
        open my $in, '<', "$ENV{HOME}/.galaxy_api_key";
        my $key = <$in>;
        chomp $key;
        $self->{key} = $key;
    }

    return $self;

}

sub version {

    my ($self) = @_;

    my $res = $self->_get('version');

    return $res->{version_major};

}

sub libraries {

    my ($self) = @_;

    my $libs = $self->_get('libraries')
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {API::Galaxy::Library->new($self, $_)} @{$libs};

}

sub _post {

    my ($self, $path, $payload, @params) = @_;

    if (defined $self->{key}) {
        push @params, ['key' => $self->{key}];
    }

    my $url = $self->{url}
        . "/$path";

    if (@params) {
        my @strings;
        for (@params) {
            my ($key, $val) = map {uri_escape($_)} @$_;
            push @strings, "$key=$val";
        }
        my $param_string = join '&', @strings;
        $url .= "?$param_string";
    }
    warn "URL: $url\n";     

    $payload = encode_json($payload);

    for (1.. $self->{retry}) {

        my $res = $self->{ua}->post( $url => {
            headers => {
                'content-type' => 'application/json',
            },
            content => $payload,
        } );

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n$res->{content}\n";
        }

        else {
            return decode_json($res->{content});
        }

    }

    return undef;

}


sub _get {

    my ($self, $path, @params) = @_;

    if (defined $self->{key}) {
        push @params, ['key' => $self->{key}];
    }

    my $url = $self->{url}
        . "/$path";

    if (@params) {
        my @strings;
        for (@params) {
            my ($key, $val) = map {uri_escape($_)} @$_;
            push @strings, "$key=$val";
        }
        my $param_string = join '&', @strings;
        $url .= "?$param_string";
    }
    warn "URL: $url\n";     

    for (1.. $self->{retry}) {

        my $res = $self->{ua}->get($url);

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n";
        }
        elsif (defined $res->{headers}->{'content-type'}
                && lc($res->{headers}->{'content-type'}) ne 'application/json') {
            warn "Error: server did not return JSON payload as expected\n";
        }
        else {
            return decode_json($res->{content});
        }

    }

    return undef;

}


__END__

=head1 NAME

API::Galaxy - Interface to the Galaxy server API


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use API::Galaxy;

    my $foo = API::Galaxy->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Jeremy Volkening, C<< <jdv at base2bio.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-galaxy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=API-Galaxy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc API::Galaxy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=API-Galaxy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/API-Galaxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/API-Galaxy>

=item * Search CPAN

L<http://search.cpan.org/dist/API-Galaxy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

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

1; # End of API::Galaxy
