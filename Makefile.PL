use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::RecordParser',
    VERSION_FROM     => 'RecordParser.pm',
    AUTHOR           => 'Ken Y. Clark <kclark@cpan.org>',
    ABSTRACT         => 'Parse record-oriented data in a text file',
    EXE_FILES        => [ 'bin/tablify' ],
    PREREQ_PM        => {
        'IO::Scalar'           => 0,
        'Text::TabularDisplay' => 1.18,
    },
    clean            => {
        FILES => '$(DISTNAME)-$(VERSION).tar.gz',
    },
);
