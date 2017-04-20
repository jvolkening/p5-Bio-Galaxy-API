package Bio::Galaxy::API;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use URI;
use HTTP::Tiny;
use Carp;
use JSON;
use URI::Escape;
use File::Basename qw/basename/;

use Bio::Galaxy::API::Library;
use Bio::Galaxy::API::Workflow;
use Bio::Galaxy::API::User;

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
        map  {Bio::Galaxy::API::Library->new($self, $_)} @{$libs};

}

sub workflows {

    my ($self) = @_;

    my $wfs = $self->_get('workflows')
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::Workflow->new($self, $_)} @{$wfs};

}

sub users {

    my ($self, $user) = @_;

    my $users = $self->_get('users', ['f_any' => $user])
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::User->new($self, $_)} @{$users};

}

sub _post {

    my ($self, $path, $payload, $fn) = @_;

    my $url = join '/',
        $self->{url},
        $path;

    for (1.. $self->{retry}) {

        my $res;
        if (defined $fn) {

            my $boundary = 'xYzZY__xYzZY__sYzZY__xYzZY__xYzZY';

            my $size = 0;
            for (keys %$payload) {
                $size += 49 + length($_) + length($payload->{$_}) +
                    length($boundary);
            }
            $size += 62 + length('files_0|file_data') + (-s $fn) +
                + length(basename($fn)) + length($boundary);
            $size += 6 + length $boundary;

            my $cb = _generator(
                $boundary,
                $payload,
                $fn,
            );

            $res = $self->{ua}->post( $url => {
                headers => {
                    'content-type'   => "multipart/form-data; boundary=$boundary",
                    'content-length' => $size,
                    'x-api-key'      => $self->{key},
                },
                content => $cb,
            } );

        }
        else {
            
            my $encoded = JSON->new->encode($payload);
            $res = $self->{ua}->post( $url => {
                headers => {
                    'content-type' => 'application/json',
                    'x-api-key'    => $self->{key},
                },
                content => $encoded,
            } );

        }

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n$res->{content}\n";
        }

        else {
            return JSON->new->allow_nonref->decode( $res->{content} );
        }

    }

    return undef;

}


sub _get {

    my ($self, $path, @params) = @_;

    my $url = join '/',
        $self->{url},
        $path;

    if (@params) {
        my @strings;
        for (@params) {
            my ($key, $val) = map {uri_escape($_)} @$_;
            push @strings, "$key=$val";
        }
        my $param_string = join '&', @strings;
        $url .= "?$param_string";
    }

    for (1.. $self->{retry}) {

        my $res = $self->{ua}->get($url => {
            headers => {
                'x-api-key' => $self->{key},
            },
        } );

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n";
        }
        elsif (defined $res->{headers}->{'content-type'}
                && lc($res->{headers}->{'content-type'}) ne 'application/json') {
            warn "Error: server did not return JSON payload as expected\n";
        }
        else {
            return JSON->new->allow_nonref->decode( $res->{content} );
        }

    }

    return undef;

}

sub _split_payload {

    my ($payload, $base) = @_;

    my $boundary = 'xYzZY__xYzZY__sYzZY__xYzZY__xYzZY';
    my $CRLF = "\015\012";

    my $chunk;

    for my $k (keys %$payload) {

        #47 + length key + length val + length boundary
        $chunk .= "--$boundary$CRLF";
        $chunk .= "Content-Disposition: form-data; name=\"$k\"$CRLF$CRLF";
        $chunk .= "$payload->{$k}$CRLF";

        #49 + length key + length val + length boundary
        #13 + length filename
        #6 + length boundary

    }
    $chunk .= "--$boundary$CRLF";
    $chunk .= "Content-Disposition: form-data; name=\"files_0|file_data\"; filename=\"$base\"$CRLF$CRLF";

    return $chunk;
            
}        

sub _generator {

    my ($boundary, $payload, $fn) = @_;

    my $n_read = 4096;
    my $done = 0;

    open my $fh, '<', $fn or die "Error open: $!\n";
    my $CRLF = "\015\012";
    my @keys = keys %$payload;
    my $base = basename($fn);

    return sub {

        return undef if ($done);

        my $chunk;

        while (scalar @keys) {
            my $k = shift @keys; 
            $chunk .= "--$boundary$CRLF";
            $chunk .= "Content-Disposition: form-data; name=\"$k\"$CRLF$CRLF";
            $chunk .= "$payload->{$k}$CRLF";
            return $chunk if (scalar @keys);
            $chunk .= "--$boundary$CRLF";
            $chunk .= "Content-Disposition: form-data; name=\"files_0|file_data\"; filename=\"$base\"$CRLF$CRLF";
            return $chunk;
        }

        while (read($fh, my $buf, $n_read)) {
            return $buf;
        }

        $done = 1;
        return "$CRLF--$boundary--$CRLF";

    }
            
}        
            




__END__

=head1 NAME

Bio::Galaxy::API - Interface to the Galaxy server API


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Bio::Galaxy::API;

    my $foo = Bio::Galaxy::API->new();
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
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Galaxy-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Galaxy::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Galaxy-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Galaxy-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Galaxy-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Galaxy-API/>

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

1; # End of Bio::Galaxy::API
