#!/usr/bin/perl

#
# test for "filename"
#

use strict;
use IO::File;
use Test::More tests => 31;
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

    my $io = IO::File->new('<t/data/simpsons.cvs');
    is ( ref $p->fh( $io ), 'GLOB', 'fh is a filehandle' );
}

#
# Data tests
#
{
    my $p      = Text::RecordParser->new;
    my $scalar = "lname,fname,age\nSmith,Joan,20\nDoe,James,21\n";

    $p->data( $scalar );
    $p->bind_header;
    my @fields = $p->field_list;
    is( $fields[0], 'lname', 'lname field' );
    is( $fields[1], 'fname', 'fname field' );
    is( $fields[2], 'age', 'age field' );

    my $rec = $p->fetchrow_hashref;
    is( $rec->{'lname'}, 'Smith', 'lname = "Smith"' );
    is( $rec->{'fname'}, 'Joan', 'fname = "Joan"' );
    is( $rec->{'age'}, '20', 'age = "20"' );

    $rec = $p->fetchrow_array;
    is( $rec->[0], 'Doe', 'lname = "Doe"' );
    is( $rec->[1], 'James', 'fname = "James"' );
    is( $rec->[2], '21', 'age = "21"' );

    $p->data( 
        "name\tinstrument\n", 
        "Miles Davis\ttrumpet\n", 
        "Art Blakey\tdrums\n" 
    );

    $p->field_separator("\t");
    $p->bind_header;
    @fields = $p->field_list;
    is( $fields[0], 'name', 'name field' );
    is( $fields[1], 'instrument', 'instrument field' );

    $rec = $p->fetchrow_array;
    is( $rec->[0], 'Miles Davis', 'name = "Miles Davis"' );
    is( $rec->[1], 'trumpet', 'instrument = "trumpet"' );

    $rec = $p->fetchrow_hashref;
    is( $rec->{'name'}, 'Art Blakey', 'name = "Art Blakey"' );
    is( $rec->{'instrument'}, 'drums', 'instrument = "drums"' );

    open my $fh, '<t/data/simpsons.cvs';
    is ( $p->data( $fh ), 1, 'data accepts a filehandle' );
    is ( UNIVERSAL::isa( $p->fh, 'GLOB' ), 1, 'fh is a GLOB' );
}

{
    my $p    = Text::RecordParser->new(
        data => "lname,fname,age\nSmith,Joan,20\nDoe,James,21\n"
    );

    $p->bind_header;
    my @fields = $p->field_list;
    is( $fields[0], 'lname', 'lname field' );
    is( $fields[1], 'fname', 'fname field' );
    is( $fields[2], 'age', 'age field' );

    my $rec = $p->fetchrow_hashref;
    is( $rec->{'lname'}, 'Smith', 'lname = "Smith"' );
    is( $rec->{'fname'}, 'Joan', 'fname = "Joan"' );
    is( $rec->{'age'}, '20', 'age = "20"' );
}
