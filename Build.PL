use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Business-DPD-shipperAPI',
    license            => 'perl',
    dist_author        => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from  => 'lib/Business/DPD/shipperAPI.pm',
    configure_requires => {'Module::Build' => '0.3607',},
    requires           => {
        'perl'                      => '5.022',    # because of Future::AsyncAwait
        'Moose'                     => '2.2014',
        'MooseX::Types::URI'        => '0.08',
        'MooseX::StrictConstructor' => '0.21',
        'URI'                       => '5.07',
        'URI::QueryParam'           => '5.07',
        'Log::Any'                  => '1.709',
        'Future'                    => '0.47',
        'Future::AsyncAwait'        => '0.48',
        'Future::HTTP::AnyEvent'    => '0.14',
        'AnyEvent::HTTP'            => '2.25',     # because of Future::HTTP::AnyEvent
        'Time::HiRes'               => '1.9764',
        'namespace::autoclean'      => '0.29',
        'HTTP::Exception'           => '0.04007',
        'List::Util'                => '1.55',
        'Run::Env'                  => '0.08',
        'JSON'                      => '0',
        'Geography::Countries'      => '0',
        'DateTime'                  => '0',
    },
    build_requires => {
        'Test::Most'       => '0.37',
        'Test::MockTime'   => '0',
    },
    add_to_cleanup => ['Business-DPD-shipperAPI-*'],
    create_readme  => 1,
    meta_merge     => {
        resources => {
            repository => 'https://github.com/meon/Business-DPD-shipperAPI',
            bugtracker => 'https://github.com/meon/Business-DPD-shipperAPI/issues',
        },
        keywords => [qw/ DPD shipper API shipperAPI integration /],
    },
);

$builder->create_build_script();
