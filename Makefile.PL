# $Id: Makefile.PL,v 1.1.1.1 2003/05/01 15:26:00 kclark Exp $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Text::RecordParser',
    VERSION_FROM => 'RecordParser.pm',
    AUTHOR       => 'Ken Y. Clark <kclark@cshl.org>',
    ABSTRACT     => 'Read record-oriented data from a file',
    clean        => {
        FILES => '$(DISTNAME)-$(VERSION).tar.gz',
    },
);
