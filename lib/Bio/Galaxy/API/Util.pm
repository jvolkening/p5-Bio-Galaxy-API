package Bio::Galaxy::API::Util;

use strict;
use warnings;

use Carp;
use Exporter qw/import/;

our @EXPORT_OK = qw/
    _check_id
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub _check_id { return $_[0] !~ /[^a-zA-Z0-9]/ }

1;
