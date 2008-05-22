use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::MockTerm',
    license             => 'perl',
    dist_author         => 'Robert Norris <rob@cataclysm.cx>',
    dist_version_from   => 'lib/Test/MockTerm.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Test-MockTerm-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
