# NAME

Text::RecordParser - read record-oriented files

# SYNOPSIS

    use Text::RecordParser;

    # use default record (\n) and field (,) separators
    my $p = Text::RecordParser->new( $file );

    # or be explicit
    my $p = Text::RecordParser->new({
        filename        => $file,
        field_separator => "\t",
    });

    $p->filename('foo.csv');

    # Split records on two newlines
    $p->record_separator("\n\n");

    # Split fields on tabs
    $p->field_separator("\t");

    # Skip lines beginning with hashes
    $p->comment( qr/^#/ );

    # Trim whitespace
    $p->trim(1);

    # Use the fields in the first line as column names
    $p->bind_header;

    # Get a list of the header fields (in order)
    my @columns = $p->field_list;

    # Extract a particular field from the next row
    my ( $name, $age ) = $p->extract( qw[name age] );

    # Return all the fields from the next row
    my @fields = $p->fetchrow_array;

    # Define a field alias
    $p->set_field_alias( name => 'handle' );

    # Return all the fields from the next row as a hashref
    my $record = $p->fetchrow_hashref;
    print $record->{'name'};
    # or
    print $record->{'handle'};

    # Return the record as an object with fields as accessors
    my $object = $p->fetchrow_object;
    print $object->name; # or $object->handle;

    # Get all data as arrayref of arrayrefs
    my $data = $p->fetchall_arrayref;

    # Get all data as arrayref of hashrefs
    my $data = $p->fetchall_arrayref( { Columns => {} } );

    # Get all data as hashref of hashrefs
    my $data = $p->fetchall_hashref('name');

# DESCRIPTION

This module is for reading record-oriented data in a delimited text
file.  The most common example have records separated by newlines and
fields separated by commas or tabs, but this module aims to provide a
consistent interface for handling sequential records in a file however
they may be delimited.  Typically this data lists the fields in the
first line of the file, in which case you should call `bind_header`
to bind the field name (or not, and it will be called implicitly).  If
the first line contains data, you can still bind your own field names
via `bind_fields`.  Either way, you can then use many methods to get
at the data as arrays or hashes.

# METHODS

## new

This is the object constructor.  It takes a hash (or hashref) of
arguments.  Each argument can also be set through the method of the
same name.

- filename

    The path to the file being read.  If the filename is passed and the fh
    is not, then it will open a filehandle on that file and sets `fh`
    accordingly.  

- comment

    A compiled regular expression identifying comment lines that should 
    be skipped.

- data

    The data to read.

- fh

    The filehandle of the file to read.

- field\_separator | fs

    The field separator (default is comma).

- record\_separator | rs

    The record separator (default is newline).

- field\_filter

    A callback applied to all the fields as they are read.

- header\_filter

    A callback applied to the column names.

- trim

    Boolean to enable trimming of leading and trailing whitespace from fields
    (useful if splitting on whitespace only).

See methods for each argument name for more information.

Alternately, if you supply a single argument to `new`, it will be 
treated as the `filename` argument.

## bind\_fields

    $p->bind_fields( qw[ name rank serial_number ] );

Takes an array of field names and memorizes the field positions for
later use.  If the input file has no header line but you still wish to
retrieve the fields by name (or even if you want to call
`bind_header` and then give your own field names), simply pass in the
an array of field names you wish to use.

Pass in an empty array reference to unset:

    $p->bind_field( [] ); # unsets fields

## bind\_header

    $p->bind_header;
    my $name = $p->extract('name');

Takes the fields from the next row under the cursor and assigns the field
names to the values.  Usually you would call this immediately after 
opening the file in order to bind the field names in the first row.

## comment

    $p->comment( qr/^#/ );  # Perl-style comments
    $p->comment( qr/^--/ ); # SQL-style comments

Takes a regex to apply to a record to see if it looks like a comment
to skip.

## data

    $p->data( $string );
    $p->data( \$string );
    $p->data( @lines );
    $p->data( [$line1, $line2, $line3] );
    $p->data( IO::File->new('<data') );

Allows a scalar, scalar reference, glob, array, or array reference as
the thing to read instead of a file handle.

It's not advised to pass a filehandle to `data` as it will read the
entire contents of the file rather than one line at a time if you set
it via `fh`.

## extract

    my ( $foo, $bar, $baz ) = $p->extract( qw[ foo bar baz ] );

Extracts a list of fields out of the last row read.  The field names
must correspond to the field names bound either via `bind_fields` or
`bind_header`.

## fetchrow\_array

    my @values = $p->fetchrow_array;

Reads a row from the file and returns an array or array reference 
of the fields.

## fetchrow\_hashref

    my $record = $p->fetchrow_hashref;
    print "Name = ", $record->{'name'}, "\n";

Reads a line of the file and returns it as a hash reference.  The keys
of the hashref are the field names bound via `bind_fields` or
`bind_header`.  If you do not bind fields prior to calling this method,
the `bind_header` method will be implicitly called for you.

## fetchrow\_object

    while ( my $object = $p->fetchrow_object ) {
        my $id   = $object->id;
        my $name = $object->naem; # <-- this will throw a runtime error
    }

This will return the next data record as a Text::RecordParser::Object
object that has read-only accessor methods of the field names and any
aliases.  This allows you to enforce field names, further helping
ensure that your code is reading the input file correctly.  That is,
if you are using the "fetchrow\_hashref" method to read each line, you
may misspell the hash key and introduce a bug in your code.  With this
method, Perl will throw an error if you attempt to read a field not
defined in the file's headers.  Additionally, any defined field
aliases will be created as additional accessor methods.

## fetchall\_arrayref

    my $records = $p->fetchall_arrayref;
    for my $record ( @$records ) {
        print "Name = ", $record->[0], "\n";
    }

    my $records = $p->fetchall_arrayref( { Columns => {} } );
    for my $record ( @$records ) {
        print "Name = ", $record->{'name'}, "\n";
    }

Like DBI's fetchall\_arrayref, returns an arrayref of arrayrefs.  Also 
accepts optional "{ Columns => {} }" argument to return an arrayref of
hashrefs.

## fetchall\_hashref

    my $records = $p->fetchall_hashref('id');
    for my $id ( keys %$records ) {
        my $record = $records->{ $id };
        print "Name = ", $record->{'name'}, "\n";
    }

Like DBI's fetchall\_hashref, this returns a hash reference of hash
references.  The keys of the top-level hashref are the field values
of the field argument you supply.  The field name you supply can be
a field created by a `field_compute`.

## fh

    open my $fh, '<', $file or die $!;
    $p->fh( $fh );

Gets or sets the filehandle of the file being read.

## field\_compute

A callback applied to the fields identified by position (or field
name if `bind_fields` or `bind_header` was called).  

The callback will be passed two arguments:

- 1

    The current field

- 2

    A reference to all the other fields, either as an array or hash 
    reference, depending on the method which you called.

If data looks like this:

    parent    children
    Mike      Greg,Peter,Bobby
    Carol     Marcia,Jane,Cindy

You could split the "children" field into an array reference with the 
values like so:

    $p->field_compute( 'children', sub { [ split /,/, shift() ] } );

The field position or name doesn't actually have to exist, which means
you could create new, computed fields on-the-fly.  E.g., if you data
looks like this:

    1,3,5
    32,4,1
    9,5,4

You could write a field\_compute like this:

    $p->field_compute( 3,
        sub {
            my ( $cur, $others ) = @_;
            my $sum;
            $sum += $_ for @$others;
            return $sum;
        }
    );

Field "3" will be created as the sum of the other fields.  This allows
you to further write:

    my $data = $p->fetchall_arrayref;
    for my $rec ( @$data ) {
        print "$rec->[0] + $rec->[1] + $rec->[2] = $rec->[3]\n";
    }

Prints:

    1 + 3 + 5 = 9
    32 + 4 + 1 = 37
    9 + 5 + 4 = 18

## field\_filter

    $p->field_filter( sub { $_ = shift; uc(lc($_)) } );

A callback which is applied to each field.  The callback will be
passed the current value of the field.  Whatever is passed back will
become the new value of the field.  The above example capitalizes
field values.  To unset the filter, pass in the empty string.

## field\_list

    $p->bind_fields( qw[ foo bar baz ] );
    my @fields = $p->field_list;
    print join ', ', @fields; # prints "foo, bar, baz"

Returns the fields bound via `bind_fields` (or `bind_header`).

## field\_positions

    my %positions = $p->field_positions;

Returns a hash of the fields and their positions bound via 
`bind_fields` (or `bind_header`).  Mostly for internal use.

## field\_separator

    $p->field_separator("\t");     # splits fields on tabs
    $p->field_separator('::');     # splits fields on double colons
    $p->field_separator(qr/\s+/);  # splits fields on whitespace
    my $sep = $p->field_separator; # returns the current separator

Gets and sets the token to use as the field delimiter.  Regular
expressions can be specified using qr//.  If not specified, it will
take a guess based on the filename extension ("comma" for ".txt," 
".dat," or ".csv"; "tab" for ".tab").  The default is a comma.  

## filename

    $p->filename('/path/to/file.dat');

Gets or sets the complete path to the file to be read.  If a file is
already opened, then the handle on it will be closed and a new one
opened on the new file.

## get\_field\_aliases

    my @aliases = $p->get_field_aliases('name');

Allows you to define alternate names for fields, e.g., sometimes your
input file calls city "town" or "township," sometimes a file uses "Moniker"
instead of "name."

## header\_filter

    $p->header_filter( sub { $_ = shift; s/\s+/_/g; lc $_ } );

A callback applied to column header names.  The callback will be
passed the current value of the header.  Whatever is returned will
become the new value of the header.  The above example collapses
spaces into a single underscore and lowercases the letters.  To unset
a filter, pass in the empty string.

## record\_separator

    $p->record_separator("\n//\n");
    $p->field_separator("\n");

Gets and sets the token to use as the record separator.  The default is 
a newline ("\\n").

The above example would read a file that looks like this:

    field1
    field2
    field3
    // 
    data1
    data2
    data3
    //

## set\_field\_alias

    $p->set_field_alias({
        name => 'Moniker,handle',        # comma-separated string
        city => [ qw( town township ) ], # or anonymous arrayref
    });

Allows you to define alternate names for fields, e.g., sometimes your
input file calls city "town" or "township," sometimes a file uses "Moniker"
instead of "name."

## trim

    my $trim_value = $p->trim(1);

Provide "true" argument to remove leading and trailing whitespace from
fields.  Use a "false" argument to disable.

# AUTHOR

Ken Youens-Clark <kclark@cpan.org>

# SOURCE

http://github.com/kyclark/text-recordparser

# CREDITS

Thanks to the following:

- Benjamin Tilly 

    For Text::xSV, the inspirado for this module

- Tim Bunce et al.

    For DBI, from which many of the methods were shamelessly stolen

- Tom Aldcroft 

    For contributing code to make it easy to parse whitespace-delimited data

- Liya Ren

    For catching the column-ordering error when parsing with "no-headers"

- Sharon Wei

    For catching bug in `extract` that sets up infinite loops

- Lars Thegler 

    For bug report on missing "script\_files" arg in Build.PL

# BUGS

None known.  Please use http://rt.cpan.org/ for reporting bugs.

# LICENSE AND COPYRIGHT

Copyright (C) 2006-10 Ken Youens-Clark.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.
