use 5.012;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::Galaxy::API',
    license             => 'GPL_3',
    dist_author         => q{Jeremy Volkening <jdv@base2bio.com>},
    dist_version_from   => 'lib/Bio/Galaxy/API.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'HTTP::Tiny' => 0,
        'JSON'       => 0,
        'URI'        => 0,
    },
    add_to_cleanup     => [ 'Bio-Galaxy-API-*' ],
);

$builder->create_build_script();
