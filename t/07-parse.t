#!/usr/bin/perl

#
# tests for alternate parsing
#

use strict;
use Test::More tests => 4;
use Text::RecordParser;

{
    my $p = Text::RecordParser->new(
        filename        => 't/data/simpsons.tab',
        field_separator => "\t",
    );
    $p->bind_header;
    my $row = $p->fetchrow_hashref;
    is( $row->{'Wife'}, 'Marge', "Wife is Marge" );
}

{
    my $p = Text::RecordParser->new(
        filename         => 't/data/simpsons.alt',
        field_separator  => "\n",
        record_separator => "\n//\n",
    );
    $p->bind_header;
    my $row = $p->fetchrow_hashref;
    is( $row->{'Wife'}, 'Marge', "Wife is still Marge" );
}

{
    my $p = Text::RecordParser->new(
        filename         => 't/data/pipe.dat',
        field_separator  => '|',
    );
    my $row = $p->fetchrow_array;
    is( $row->[0], 'MSH', "First field is 'MSH'" );
    is( $row->[-1], '2.2', "Last field is '2.2'" );
}
