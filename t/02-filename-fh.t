#!/usr/bin/perl

#
# test for "filename"
#

use strict;
use Test::More tests => 7;
use Text::RecordParser;

{
    my $p = Text::RecordParser->new;

    is( $p->filename, '', "Filename is blank" );

    my $file = 't/data/simpsons.csv';
    is( $p->filename($file), $file, "Filename is '$file'" );

    my $dir = 't/data';
    eval {
        $p->filename($dir);
    };
    my $err = $@;

    like($err, qr/cannot use dir/i, "filename rejects directory for argument");

    my $bad_file = 't/data/non-existent';
    eval {
        $p->filename($bad_file);
    };
    $err = $@;
    like($err, qr/file does not exist/i, "filename rejects non-existent file");
}

#
# Filehandle tests
#
{
    my $p = Text::RecordParser->new;

    open my $fh, '<t/data/simpsons.cvs';
    is ( ref $p->fh( $fh ), 'GLOB', 'fh is a filehandle' );

    #
    # Cause an error by closing the existing fh.
    #
    close $fh;
    open my $fh2, '<t/data/simpsons.tab';
    eval { $p->fh( $fh2 ) };
    my $err = $@;
    like ( $err, qr/can't close existing/i, 'fh catches bad close' );

    eval { $p->fh('') };
    $err = $@;
    like ( $err, qr/doesn't look like a filehandle/i, 'fh catches bad arg' );
}
