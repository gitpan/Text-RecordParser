#!/usr/bin/perl

#
# tests for field and record compute
#

use strict;
use Test::More tests => 7;
use Text::RecordParser;

{
    my $p             =  Text::RecordParser->new( 
        filename      => 't/data/simpsons.csv',
        header_filter => sub { lc shift }, 
        field_filter  => sub { $_ = shift; s/^\s+|\s+$//g; s/"//g; $_ },
    );
    $p->bind_header;

    eval { $p->field_compute( 'children', 'foo' ) };
    my $err = $@;
    like( $err, qr/not code/i, 'field_compute rejects not code' );

    $p->field_compute( 'children', sub { [ split /,/, shift() ] } );
    $p->field_compute( 'wife', 
        sub { 
            my ( $field, $others ) = @_;
            my $husband =  $others->{'name'} || '';
            $husband    =~ s/^.*?,\s*//;
            return $field.', wife of '.$husband;
        } 
    );

    my $row      = $p->fetchrow_hashref;
    my $children = $row->{'children'};
    is( scalar @{ $children || [] }, 3, 'Three children' );
    is( $children->[0], 'Bart', "Firstborn is Bart" );
    is( $row->{'wife'}, 'Marge, wife of Homer', "Marge is still Homer's wife" );
}

{
    my $p =  Text::RecordParser->new( filename => 't/data/numbers.csv' );
    $p->field_compute( 3, 
        sub { 
            my ( $cur, $others ) = @_;
            my $sum; 
            $sum += $_ for @$others;
            return $sum;
        } 
    );
    my $data = $p->fetchall_arrayref;
    my $rec  = $data->[0];
    is( $rec->[-1], 9, 'Sum is 9' );
    $rec     = $data->[1];
    is( $rec->[-1], 37, 'Sum is 37' );
    $rec     = $data->[2];
    is( $rec->[-1], 18, 'Sum is 18' );
}
