#!/usr/bin/perl

#
# tests for "extract" and "fetch*" methods
#

use strict;
use Test::More tests => 20;
use Text::RecordParser;

{
    my $p = Text::RecordParser->new;

    $p->filename('t/data/simpsons.csv');
    $p->bind_header;

    # Extract nothing
    my $undef = $p->extract;
    is( $undef, undef, 'Fetched nothing' );

    # Extract one thing
    my $name = $p->extract('Name');
    is( $name, '"Simpson, Homer"', 'Name is "Simpson, Homer"' );

    # Extract several things
    my ( $address, $city ) = $p->extract(qw[ Address City ]);
    is( $address, '748 Evergreen Terrace', 
        'Address is "748 Evergreen Terrace"' 
    );
    is( $city, 'Springfield', 'City is "Springfield"' );
}

{
    my $p = Text::RecordParser->new;

    $p->filename('t/data/simpsons.csv');
    $p->bind_header;

    my @row = $p->fetchrow_array;
    is( $row[0], '"Simpson, Homer"', 'Field "Simpson, Homer"' );
    is( $row[1], '747 Evergreen Terrace', 'Field "747 Evergreen Terrace"' );

    my $row = $p->fetchrow_hashref;
    is( $row->{'Name'}, '"Flanders, Ned"', 'Name is "Flanders, Ned"' );
    is( $row->{'City'}, 'Springfield', 'City is "Springfield"' );
    is( $row->{'State'}, '', 'State is empty' );
}

{
    my $p = Text::RecordParser->new;

    $p->filename('t/data/simpsons.csv');
    $p->bind_header;

    my $data = $p->fetchall_arrayref;
    is( scalar @$data, 2, 'fetchall_arrayref gets 2 records' );
    my $row = $data->[0];
    is( $row->[0], '"Simpson, Homer"', 'Field "Simpson, Homer"' );
    is( $row->[1], '747 Evergreen Terrace', 'Field "747 Evergreen Terrace"' );
}

{
    my $p = Text::RecordParser->new;

    $p->filename('t/data/simpsons.csv');
    $p->bind_header;

    my $data = $p->fetchall_arrayref( { Columns => {} } );
    is( scalar @$data, 2, 'fetchall_hashref gets 2 records' );
    my $row = $data->[1];
    is( $row->{'Name'}, '"Flanders, Ned"', 'Name is "Flanders, Ned"' );
    is( $row->{'City'}, 'Springfield', 'City is "Springfield"' );
    is( $row->{'State'}, '', 'State is empty' );
}

{
    my $p = Text::RecordParser->new;

    $p->filename('t/data/simpsons.csv');
    $p->bind_header;

    my $data = $p->fetchall_hashref('Name');
    is( scalar keys %$data, 2, 'fetchall_hashref gets 2 records' );
    my $row = $data->{'"Simpson, Homer"'};
    is( $row->{'Wife'}, 'Marge', 'Wife is "Marge"' );
}

{
    my $p = Text::RecordParser->new;

    $p->filename('t/data/simpsons.csv');
    $p->bind_header;

    $p->field_compute( 
        'crazy_name', 
        sub { 
            my ( $field, $others ) = @_; 
            my $name = $others->{'Name'};
            $name =~ s/"//g;
            $name =~ s/^.*,\s+//g;
            return "Crazy $name!";
        } 
    );

    my $data = $p->fetchall_hashref('crazy_name');
    is( scalar keys %$data, 2, 'fetchall_hashref gets 2 records' );
    my $row = $data->{'Crazy Homer!'};
    is( $row->{'Wife'}, 'Marge', 'Wife is "Marge"' );
}
