#!/usr/bin/perl

use strict;
use FindBin '$Bin';
use Test::More tests => 10;

my $tabmerge = "$Bin/../bin/tabmerge";
ok( -e $tabmerge, "Script exists" );

SKIP: {
    eval { require Text::TabularDisplay };

    skip 'Text::TabularDisplay not installed', 9 if $@;

    skip 'Text::TabularDisplay problems', 9;

    my @files = map { "$Bin/data/merge" . $_ . ".tab" } ( 1..3 );
    for my $file ( @files ) {
        ok( -e $file, "Data file '$file' exists" );
    }
    my $data = join( ' ', @files );

    my @tests = (
    {
        name     => 'List',
        command  => "$tabmerge --list $data",
        expected => 
    '+-----------+-------------------+
    | Field     | No. Times Present |
    +-----------+-------------------+
    | lod_score | 1                 |
    | name      | 3                 |
    | position  | 3                 |
    | type      | 2                 |
    +-----------+-------------------+
    '
    },
    {
        name     => 'Merge min',
        command  => "$tabmerge $data",
        expected => 
    '+----------+----------+
    | name     | position |
    +----------+----------+
    | RM104    | 2.30     |
    | RM105    | 4.5      |
    | TX5509   | 10.4     |
    | UU189    | 19.0     |
    | Xpsm122  | 3.3      |
    | Xpsr9556 | 4.5      |
    | DRTL     | 2.30     |
    | ALTX     | 4.5      |
    | DWRF     | 10.4     |
    +----------+----------+
    '
    },
    {
        name     => 'Merge max',
        command  => "$tabmerge --max $data",
        expected => 
    '+-----------+----------+----------+--------+
    | lod_score | name     | position | type   |
    +-----------+----------+----------+--------+
    |           | RM104    | 2.30     | RFLP   |
    |           | RM105    | 4.5      | RFLP   |
    |           | TX5509   | 10.4     | AFLP   |
    | 2.4       | UU189    | 19.0     | SSR    |
    | 1.2       | Xpsm122  | 3.3      | Marker |
    | 1.2       | Xpsr9556 | 4.5      | Marker |
    |           | DRTL     | 2.30     |        |
    |           | ALTX     | 4.5      |        |
    |           | DWRF     | 10.4     |        |
    +-----------+----------+----------+--------+
    '
    },
    {
        name     => 'Merge on named fields',
        command  => "$tabmerge -f name,type $data", 
        expected => 
    '+----------+--------+
    | name     | type   |
    +----------+--------+
    | RM104    | RFLP   |
    | RM105    | RFLP   |
    | TX5509   | AFLP   |
    | UU189    | SSR    |
    | Xpsm122  | Marker |
    | Xpsr9556 | Marker |
    | DRTL     |        |
    | ALTX     |        |
    | DWRF     |        |
    +----------+--------+
    '
    },
    {
        name     => 'Merge on named fields and sort',
        command  => "$tabmerge -f name,lod_score -s name $data",
        expected => 
    '+----------+-----------+
    | name     | lod_score |
    +----------+-----------+
    | ALTX     |           |
    | DRTL     |           |
    | DWRF     |           |
    | RM104    |           |
    | RM105    |           |
    | TX5509   |           |
    | UU189    | 2.4       |
    | Xpsm122  | 1.2       |
    | Xpsr9556 | 1.2       |
    +----------+-----------+
    '
    },
    {
        name     => 'Merge on named fields and sort, print stdout',
        command  => "$tabmerge -f name,lod_score -s name --stdout $data",
        expected => 
    'name	lod_score
    ALTX	
    DRTL	
    DWRF	
    RM104	
    RM105	
    TX5509	
    UU189	2.4
    Xpsm122	1.2
    Xpsr9556	1.2
    '
    },
    );

    for my $test ( @tests ) {
        my $out = `$test->{'command'}`;
        is( $out, $test->{'expected'}, $test->{'name'} || 'Parsing' );
    }
};
