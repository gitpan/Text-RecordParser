#!/usr/bin/perl

#
# tests for "bind_fields" and "bind_header"
#

use strict;
use Test::More tests => 9;
use Text::RecordParser;
use FindBin '$Bin';

{
    my $p = Text::RecordParser->new;
    
    eval { my @field_list = $p->field_list };
    my $err = $@;
    like( $err, qr/no fields/i, 'Error on "field_list" before bind' );

    is( $p->bind_fields(qw[ foo bar baz ]), 1, 'Bind fields successful' );
    my @fields = $p->field_list;
    is( $fields[0], 'foo', 'Field "foo"' );
    is( $fields[1], 'bar', 'Field "bar"' );
    is( $fields[2], 'baz', 'Field "baz"' );

    $p->filename("$Bin/data/simpsons.csv");
    is( $p->bind_header, 1, 'Bind header successful' );
    @fields = $p->field_list;
    is( $fields[0], 'Name', 'Field "Name"' );
    is( $fields[2], 'City', 'Field "City"' );
    is( $fields[-1], 'Dependents', 'Field "Dependents"' );
}
