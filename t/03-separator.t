#!/usr/bin/perl

#
# test for "field_separator" and "record_separator"
#

use strict;
use Test::More tests => 6;
use Text::RecordParser;

my $p = Text::RecordParser->new;
is( $p->field_separator, ',', 'Field separator is comma' );
is( $p->field_separator("\t"), "\t", 'Field separator is tab' );
is( $p->field_separator('::'), '::', 'Field separator is double colon' );

is( $p->record_separator, "\n", 'Record separator is newline' );
is( $p->record_separator("\n\n"), "\n\n", 
    'Record separator is double newline' 
);
is( $p->record_separator(':'), ':', 'Record separator is colon' );
