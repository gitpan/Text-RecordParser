use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::RecordParser',
    VERSION_FROM     => 'RecordParser.pm',
    AUTHOR           => 'Ken Y. Clark <kclark@cpan.org>',
    ABSTRACT         => 'Read record-oriented data from a file',
    PREREQ_PM        => {
        'IO::Scalar' => 0,
    },
    clean            => {
        FILES => '$(DISTNAME)-$(VERSION).tar.gz',
    },
);
