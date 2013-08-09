use strict;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'TRP::Builder',
    code  => q*
        sub ACTION_docs {
            require 'Pod/Readme.pm';
            require 'Pod/Select.pm';
            require 'Pod/Markdown.pm';

            my $self = shift;
            my $pod  = 'README.pod';

            podselect({ -output => $pod }, 'lib/Text/RecordParser.pm');

            my $parser = Pod::Readme->new();

            $parser->parse_from_file('README.pod', 'README');

            open my $pod_fh, '<', $pod        or die "Can't read POD '$pod'";
            open my $md_fh , '>', 'README.md' or die "Can't write README.md";

            my $md = Pod::Markdown->new;
            $md->parse_from_filehandle($pod_fh);
            print $md_fh $md->as_markdown;

            close $pod_fh;
            close $md_fh;

            return $self->SUPER::ACTION_docs;
        }
    *
);

my $build = $class->new(
    module_name        => 'Text::RecordParser',
    dist_author        => 'Ken Youens-Clark <kclark@cpan.org>',
    dist_version_from  => 'lib/Text/RecordParser.pm',
    add_to_cleanup     => [ '$(DISTNAME)-$(VERSION).tar.gz' ],
    dist_abstract      => 'Parse record-oriented data in a text file',
    license            => 'gpl',
    script_files       => ['bin/tablify', 'bin/tabmerge', 'bin/tab2graph'],

    configure_requires         => {
        'Module::Build'        => 0.40,
        'Pod::Markdown'        => 0,
        'Pod::Readme'          => 0,
        'Pod::Select'          => 0,
    },

    requires                   => {
        'IO::Scalar'           => 0,
        'Class::Accessor'      => 0,
        'Readonly'             => 0,
        'List::Util'           => 0,
        'List::MoreUtils'      => 0,
        'Text::Autoformat'     => 0,
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
