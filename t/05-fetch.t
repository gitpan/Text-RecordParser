#!perl

#
# tests for "extract" and "fetch*" methods
#

use strict;
use File::Spec::Functions;
use FindBin '$Bin';
use Readonly;
use Test::Exception;
use Test::More tests => 30;
use Text::RecordParser;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );
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
    my $file = catfile( $TEST_DATA_DIR, 'empty' );
    my $p    = Text::RecordParser->new( $file );

    throws_ok { my $data = $p->extract( qw[ foo ] ) } qr/Can't find columns/, 
        'extract dies without bound fields';

    $p->bind_fields( qw[ foo bar baz ] );
    my $data = $p->extract( qw[ foo ] );
    is( $data, undef, 'extract returns undef on read of empty file' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p   = Text::RecordParser->new( $file );
    $p->bind_header;

    throws_ok { my $data = $p->extract('non-existent-field') }
        qr/invalid field/i, 'extract dies on bad field request';
}

{
    my $file = catfile( $TEST_DATA_DIR, 'bad-file' );
    my $p = Text::RecordParser->new( $file );

    throws_ok { my @row = $p->fetchrow_array } qr/Error reading line number/, 
        'fetchrow_array dies reading invalid data';
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );
    my $row  = $p->fetchrow_hashref;
    is( $row->{'City'}, 'Springfield',
        'fetchrow_hashref works without binding fields' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );
    $p->bind_header;

    my @row = $p->fetchrow_array;
    is( $row[0], '"Simpson, Homer"', 'Field "Simpson, Homer"' );
    is( $row[1], '747 Evergreen Terrace', 'Field "747 Evergreen Terrace"' );
    is( $row[-1], q["Bart,Lisa,Maggie,Santa's Little Helper"],
        'Correct dependents list'
    );

    my $row = $p->fetchrow_hashref;
    is( $row->{'Name'}, '"Flanders, Ned"', 'Name is "Flanders, Ned"' );
    is( $row->{'City'}, 'Springfield', 'City is "Springfield"' );
    is( $row->{'State'}, '', 'State is empty' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );
    $p->bind_header;

    my $data = $p->fetchall_arrayref;
    is( scalar @$data, 2, 'fetchall_arrayref gets 2 records' );
    my $row = $data->[0];
    is( $row->[0], '"Simpson, Homer"', 'Field "Simpson, Homer"' );
    is( $row->[1], '747 Evergreen Terrace', 'Field "747 Evergreen Terrace"' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv');
    my $p    = Text::RecordParser->new( $file );
    $p->bind_header;

    my $data = $p->fetchall_arrayref( { Columns => {} } );
    is( scalar @$data, 2, 'fetchall_hashref gets 2 records' );
    my $row = $data->[1];
    is( $row->{'Name'}, '"Flanders, Ned"', 'Name is "Flanders, Ned"' );
    is( $row->{'City'}, 'Springfield', 'City is "Springfield"' );
    is( $row->{'State'}, '', 'State is empty' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );
    $p->bind_header;

    my $data = $p->fetchall_arrayref('Bad');
    is( scalar @$data, 2, 'fetchall_arrayref ignores bad param' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv');
    my $p    = Text::RecordParser->new( $file );
    $p->bind_header;

    throws_ok { my $data = $p->fetchall_hashref('Bad Field') }
        qr/Invalid key field/, 'fetchall_hashref dies on bad field';
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p = Text::RecordParser->new( $file );
    $p->bind_header;

    my $data = $p->fetchall_hashref('Name');
    is( scalar keys %$data, 2, 'fetchall_hashref gets 2 records' );
    my $row = $data->{'"Simpson, Homer"'};
    is( $row->{'Wife'}, 'Marge', 'Wife is "Marge"' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p    = Text::RecordParser->new( $file );
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

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.ssv' );
    my $p    = Text::RecordParser->new(
        trim            => 1,
        field_separator => qr/\s+/,
        filename        => $file,
    );
    $p->bind_header;

    my $row = $p->fetchrow_hashref;
    is( $row->{'Address'}, '747 Evergreen Terrace', 
        'Address is "747 Evergreen Terrace"' );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'simpsons.pdd' );
    my $p = Text::RecordParser->new(
        trim            => 1,
        field_separator => '|',
        filename        => $file,
    );
    $p->bind_header;

    my $row = $p->fetchrow_hashref;
    is( $row->{'Address'}, '747 Evergreen Terrace', 
        'Address is "747 Evergreen Terrace"' );
}
