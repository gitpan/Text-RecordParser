#!/usr/bin/perl

use strict;
use Config;
use FindBin '$Bin';
use Test::More tests => 10;

my $tablify = "$Bin/../bin/tablify";
ok( -e $tablify, "Script exists" );

my $data = "$Bin/data/people.dat";
ok( -e $data, "Data file exists" );

my $nh_data = "$Bin/data/people-no-header.dat";
ok( -e $nh_data, "Other data file exists" );

my @tests = (
{
    name     => 'Field list',
    command  => "$tablify --fs ',' -l $data",
    expected => 
'+-----------+-----------+
| Field No. | Field     |
+-----------+-----------+
| 1         | name      |
| 2         | rank      |
| 3         | serial_no |
| 4         | is_living |
| 5         | age       |
+-----------+-----------+
'
},
{
    name     => 'Select fields by name',
    command  => "$tablify --fs ',' -f name,serial_no $data",
    expected => 
'+--------+-----------+
| name   | serial_no |
+--------+-----------+
| George | 190293    |
| Dwight | 908348    |
| Attila |           |
| Tojo   |           |
| Tommy  | 998110    |
+--------+-----------+
5 records returned
'
},
{
    name     => 'Select fields by position',
    command  => "$tablify --fs ',' -f 1-3,5 $data",
    expected => 
'+--------+---------+-----------+------+
| name   | rank    | serial_no | age  |
+--------+---------+-----------+------+
| George | General | 190293    | 64   |
| Dwight | General | 908348    | 75   |
| Attila | Hun     |           | 56   |
| Tojo   | Emporor |           | 87   |
| Tommy  | General | 998110    | 54   |
+--------+---------+-----------+------+
5 records returned
'
},
{
    name     => 'Filter with regex',
    command  => "$tablify --fs ',' -w 'serial_no=~/^\\d{6}\$/' $data",
    expected => 
'+--------+---------+-----------+-----------+------+
| name   | rank    | serial_no | is_living | age  |
+--------+---------+-----------+-----------+------+
| George | General | 190293    | 0         | 64   |
| Dwight | General | 908348    | 0         | 75   |
| Tommy  | General | 998110    | 1         | 54   |
+--------+---------+-----------+-----------+------+
3 records returned
'
},
{
    name     => 'Filter with Perl operator',
    command  => "$tablify --fs ',' -w 'name eq \"Dwight\"' $data",
    expected => 
'+--------+---------+-----------+-----------+------+
| name   | rank    | serial_no | is_living | age  |
+--------+---------+-----------+-----------+------+
| Dwight | General | 908348    | 0         | 75   |
+--------+---------+-----------+-----------+------+
1 record returned
'
},
{
    name     => 'Combine filter and field selection',
    command  => "$tablify --fs ',' -f name -w 'is_living==1' ".
                "-w 'serial_no>0' $data",
    expected => 
'+-------+
| name  |
+-------+
| Tommy |
+-------+
1 record returned
'
},
{
    name     => 'No headers plus filtering by position',
    command  => "$tablify --fs ',' --no-headers -w '3 eq \"General\"' $nh_data",
    expected => 
'+--------+--------+---------+--------+--------+
| Field1 | Field2 | Field3  | Field4 | Field5 |
+--------+--------+---------+--------+--------+
| 64     | George | General | 190293 | 0      |
| 75     | Dwight | General | 908348 | 0      |
| 54     | Tommy  | General | 998110 | 1      |
+--------+--------+---------+--------+--------+
3 records returned
'
},
);

my $perl = $Config{'perlpath'};
for my $test ( @tests ) {
    my $out = `$perl $test->{'command'}`;
    is( $out, $test->{'expected'}, $test->{'name'} || 'Parsing' );
}

