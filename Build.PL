use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Text::RecordParser',
    dist_author        => 'Ken Youens-Clark <kclark@cpan.org>',
    dist_version_from  => 'lib/Text/RecordParser.pm',
    add_to_cleanup     => [ '$(DISTNAME)-$(VERSION).tar.gz' ],
    create_readme      => 1,
    dist_abstract      => 'Parse record-oriented data in a text file',
    license            => 'gpl',
    script_files       => ['bin/tablify', 'bin/tabmerge', 'bin/tab2graph'],
    requires                   => {
        'IO::Scalar'           => 0,
        'Class::Accessor'      => 0,
        'Readonly'             => 0,
        'List::Util'           => 0,
        'List::MoreUtils'      => 0,
        'version'              => 0,
    },
    build_requires             => {
        'Test::More'           => 0,
        'Test::Exception'      => 0,
    },
    recommends                 => {
        'Readonly::XS'         => 0,
        'Text::TabularDisplay' => '1.22',
        'GraphViz'             => 0,
    },
);
  
$build->create_build_script;