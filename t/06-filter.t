#!/usr/bin/perl

#
# tests for "header_filter" and "field_filter"
#

use strict;
use Test::More tests => 13;
use Text::RecordParser;
use FindBin '$Bin';

{
    my $p = Text::RecordParser->new;
    is( $p->header_filter, '', 'Header filter is blank' );

    eval { $p->header_filter('foo') };
    my $err = $@;
    like( $err, qr/doesn't look like code/, 
        'Header filter rejects bad argument' 
    );
    is( ref $p->header_filter( sub { lc shift } ),
        'CODE', 'Header filter takes value' 
    );

    is( $p->header_filter(''), '', 'Header filter resets to nothing' );

    is( $p->field_filter, '', 'Field filter is blank' );

    eval { $p->field_filter('foo') };
    $err = $@;
    like( $err, qr/doesn't look like code/, 
        'Field filter rejects bad argument' 
    );

    is( ref $p->field_filter( sub { lc shift } ),
        'CODE', 'Field filter takes value' 
    );

    is( $p->field_filter(''), '', 'Field filter resets to nothing' );

    $p->header_filter( sub { lc shift } );
    $p->field_filter( sub { uc shift } );
    $p->filename("$Bin/data/simpsons.csv");
    $p->bind_header;
    my @fields = $p->field_list;
    is( $fields[0], 'name', 'Field "name"' );
    is( $fields[2], 'city', 'Field "city"' );
    is( $fields[-1], 'dependents', 'Field "dependents"' );

    my @row = $p->fetchrow_array;
    is( $row[2], 'SPRINGFIELD', 'City is "SPRINGFIELD"' );
    is( $row[4], 'MARGE', 'Wife is "MARGE"' );
}
