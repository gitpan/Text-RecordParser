#!/usr/bin/perl

#
# tests for skipping records matching a comment regex
#

use strict;
use Test::More tests => 5;
use Text::RecordParser;

{
    my $p = Text::RecordParser->new; 
    eval { $p->comment('foo') };
    my $err = $@;
    like( $err, qr/look like a regex/i, 'comment rejects not regex' );
}

{
    my $p        =  Text::RecordParser->new( 
        filename => 't/data/commented.dat',
        comment  => qr/^#/,
    );

    $p->bind_header;
    my $row1 = $p->fetchrow_hashref;
    is( $row1->{'field1'}, 'foo', 'Field is "foo"' );

    my $row2 = $p->fetchrow_hashref;
    is( $row2->{'field2'}, 'bang', 'Field is "bang"' );
}

{
    my $p        =  Text::RecordParser->new( 
        filename => 't/data/commented2.dat',
        comment  => qr/^--/,
    );

    $p->bind_header;
    my $row1 = $p->fetchrow_hashref;
    is( $row1->{'field1'}, 'foo', 'Field is "foo"' );

    my $row2 = $p->fetchrow_hashref;
    is( $row2->{'field2'}, 'bang', 'Field is "bang"' );
}
