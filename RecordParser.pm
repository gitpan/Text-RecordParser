package Text::RecordParser;

# $Id: RecordParser.pm,v 1.5 2003/06/27 21:48:09 kclark Exp $

=head1 NAME

Text::RecordParser - read record-oriented files

=head1 SYNOPSIS

  use Text::RecordParser;
  my $p = Text::RecordParser->new;
  $p->filename('foo.csv');

  # Split records on two newlines
  $p->record_separator("\n\n");

  # Split fields on tabs
  $p->field_separator("\t");

  # Use the fields in the first line as column names
  $p->bind_header;

  # Get a list of the header fields (in order)
  my @columns = $p->field_list;

  # Extract a particular field from the next row
  my ( $name, $age ) = $p->extract( qw[name age] );

  # Return all the fields from the next row
  my @fields = $p->fetchrow_array;

  # Return all the fields from the next row as a hashref
  my $record = $p->fetchrow_hashref;
  print $record->{'name'};

  # Get all data as arrayref of arrayrefs
  my $data = $p->fetchall_arrayref;

  # Get all data as arrayref of hashrefs
  my $data = $p->fetchall_arrayref( { Columns => {} } );

  # Get all data as hashref of hashrefs
  my $data = $p->fetchall_hashref('name');

=head1 DESCRIPTION

This module is for reading record-oriented data.  The most common
example have records separated by newlines and fields separated by
commas or tabs, but this module aims to provide a consistent interface
for handling sequential records in a file however they may be
delimited.  Typically this data lists the fields in the first line of
the file, in which case you should call C<bind_header> to bind the
field name.  If the first line contains data, you can still bind your
own field names via C<bind_fields>.  Either way, you can then use many
methods to get at the data as arrays or hashes.

Many of the methods were shamelessly stolen from DBI and the original
inspiration for this module, Text::xSV by Benjamin Tilly.

=head1 METHODS

=cut

use strict;
use Carp 'croak';
use Text::ParseWords 'parse_line';
use IO::Scalar;

use vars '$VERSION';
$VERSION = 0.03;

# ----------------------------------------------------------------
sub new {

=pod

=head2 new

This is the constructor.  It takes a hash of optional arguments.  Each
argument can also be set through the method of the same name.

=over 4

=item * filename

The path to the file being read.  If the filename is passed and the fh
is not, then it will open a filehandle on that file and sets C<fh>
accordingly.  

=item * data

The data to read

=item * fh

The filehandle of the file to read.

=item * field_separator

The field separator (default is comma).

=item * record_separator

The record separator (default is newline).

=item * field_filter

A callback applied to all the fields as they are read.

=item * header_filter

A callback applied to the column names.

=back

See methods for each argument name for more information.

Alternately, if you supply a single argument to C<new>, it will be 
treated as the C<filename> argument.

=cut

    my $class = shift;
    my $args  = defined $_[0] && UNIVERSAL::isa( $_[0], 'HASH' ) ? shift 
                : scalar @_ == 1 ? { filename => shift }
                : { @_ };

    my $self  = bless {}, $class;

    my $data_handles = 0;
    for my $arg ( 
        qw[ filename fh header_filter field_filter 
            field_separator record_separator data
        ] 
    ) {
        next unless $args->{ $arg };
        $data_handles++ if $arg eq 'filename' ||
            $arg eq 'fh' || $arg eq 'data';
        $self->$arg( $args->{ $arg } );
    }

    croak(
        'Passed too many arguments to read the data. '.
        'Please choose only one of "filename," "fh," or "data."'
    ) if $data_handles > 1;

    return $self;
}

# ----------------------------------------------------------------
sub bind_fields {

=pod

=head2 bind_fields

Takes an array of field names and memorizes the field positions for 
later use.

  $p->bind_fields( qw[ name rank serial_number ] );

=cut

    my $self   = shift;
    my @fields = @_ or return;
    $self->{'field_pos_ordered'} = [ @fields ];

    my %field_pos;
    foreach my $i ( 0 .. $#fields ) {
        $field_pos{ $fields[$i] } = $i;
    }

    $self->{'field_pos'} = \%field_pos;

    return 1;
}

# ----------------------------------------------------------------
sub bind_header {

=pod

=head2 bind_header

Takes the fields from the next row under the cursor and assigns the field
names to the values.  Usually you would call this immediately after 
opening the file in order to bind the field names in the first row.

  $p->bind_header;
  my $name = $p->extract('name');

=cut

    my $self    = shift;
    my @columns = $self->fetchrow_array or croak(
        "Can't find columns in file '", $self->filename, "'"
    );

    if ( my $filter = $self->header_filter ) {
        for my $i ( 0 .. $#columns ) {
            $columns[ $i ] = $filter->( $columns[ $i ] );
        }
    }

    $self->bind_fields( @columns );

    return 1;
}

# ----------------------------------------------------------------
sub data {

=pod

=head2 data

Allows a scalar, scalar reference, glob, array, or array reference as
the thing to read instead of a file handle.

  $p->data( $string );
  $p->data( \$string );
  $p->data( @lines );
  $p->data( [ $line1, $line2, $line3] );
  $p->data( IO::File->new('<data') );

It's not advised to pass a filehandle to C<data> as it will read the
entire contents of the file rather than one line at a time if you set
it via C<fh>.

=cut

    my $self = shift;
    my $data;

    if ( @_ ) {
        my $arg = shift;

        if ( UNIVERSAL::isa( $arg, 'SCALAR' ) ) {
            $data = $$arg;
        }
        elsif ( UNIVERSAL::isa( $arg, 'ARRAY' ) ) {
            $data = join '', @$arg;
        }
        elsif ( UNIVERSAL::isa( $arg, 'GLOB' ) ) {
            local $/;
            $data = <$arg>;
        }
        elsif ( ! ref $arg && @_ ) {
            $data = join '', $arg, @_;
        }
        else {
            $data = $arg;
        }
    }

    if ( $data ) {
        my $fh = IO::Scalar->new( \$data );
        $self->fh( $fh );
    }

    return 1;
}

# ----------------------------------------------------------------
sub extract {

=pod

=head2 extract

Extracts a list of fields out of the last row read.  The field names
must correspond to the field names bound either via C<bind_fields> or
C<bind_header>.

  my ( $foo, $bar, $baz ) = $p->extract( qw[ foo bar baz ] );

=cut

    my $self    = shift;
    my @fields  = @_ or return;
    my $record  = $self->fetchrow_hashref;
    my %allowed = map { $_, 1 } $self->field_list;

    unless ( %allowed ) {
        croak("Can't call extract without binding fields");
    }

    my @data;
    foreach my $field ( @fields ) {
        if ( $allowed{ $field } ) {
            push @data, $record->{ $field };
        }
        else {
            croak(
                "Invalid field $field for file '".$self->filename."'.\n" .
                'Valid fields are: ' . join(', ', $self->field_list) . "\n"
            );
        }
    }

    return scalar @data == 1 ? $data[0] : @data;
}

# ----------------------------------------------------------------
sub fetchrow_array {

=pod

=head2 fetchrow_array

Reads a row from the file and returns an array or array reference 
of the fields.

  my @values = $p->fetchrow_array;

=cut

    my $self = shift;
    my $fh   = $self->fh;
    local $/ = $self->record_separator;
    defined( my $line = <$fh> ) or return;
    chomp( $line );

    my @fields = parse_line( $self->field_separator, 1, $line );

    if ( my $filter = $self->field_filter ) {
        @fields = map { $filter->( $_ ) } @fields;
    }

    while ( my ( $position, $callback ) = each %{ $self->field_compute } ) {
        next unless $position =~ m/^\d+$/;
        $fields[ $position ] = $callback->( $fields[ $position ], \@fields );
    }

    return wantarray ? @fields : \@fields;
}

# ----------------------------------------------------------------
sub fetchrow_hashref {

=pod

=head2 fetchrow_hashref

Reads a line of the file and returns it as a hash reference.  The keys
of the hashref are the field names bound via C<bind_fields> or
C<bind_header>.

  my $record = $p->fetchrow_hashref;
  print "Name = ", $record->{'name'}, "\n";

=cut

    my $self   = shift;
    my @row    = $self->fetchrow_array or return;
    my @fields = $self->field_list or croak(
        "Can't find field list.  Did you bind_fields or bind_header?"
    );

    my %return;
    my $i = 0;
    for my $field ( @fields ) {
        $return{ $field } = $row[ $i++ ];
    }

    while ( my ( $position, $callback ) = each %{ $self->field_compute } ) {
        $return{ $position } = $callback->( $return{ $position }, \%return );
    }

    return \%return;
}

# ----------------------------------------------------------------
sub fetchall_arrayref {

=pod

=head2 fetchall_arrayref

Like DBI's fetchall_arrayref, returns an arrayref of arrayrefs.  Also 
accepts optional "{ Columns => {} }" argument to return an arrayref of
hashrefs.

  my $records = $p->fetchall_arrayref;
  for my $record ( @$records ) {
      print "Name = ", $record->[0], "\n";
  }

  my $records = $p->fetchall_arrayref( { Columns => {} } );
  for my $record ( @$records ) {
      print "Name = ", $record->{'name'}, "\n";
  }

=cut

    my $self   = shift;
    my %args   = ref $_[0] eq 'HASH' ? %{ shift() } : @_;
    my $method = ref $args{'Columns'} eq 'HASH' 
                 ? 'fetchrow_hashref' : 'fetchrow_array';

    my @return;
    while ( my $record = $self->$method() ) {
        push @return, $record;
    }

    return \@return;
}

# ----------------------------------------------------------------
sub fetchall_hashref {

=pod

=head2 fetchall_hashref

Like DBI's fetchall_hashref, this returns a hash reference of hash
references.  The keys of the top-level hashref are the field values
of the field argument you supply.  The field name you supply can be
a field created by a C<field_compute>.

  my $records = $p->fetchall_hashref('id');
  for my $id ( keys %$records ) {
      my $record = $records->{ $id };
      print "Name = ", $record->{'name'}, "\n";
  }

=cut

    my $self      = shift;
    my $key_field = shift || return croak('No key field');
    my @fields    = $self->field_list or croak(
        "Can't find field list.  Did you bind_fields or bind_header?"
    );

    my ( %return, $field_ok );
    while ( my $record = $self->fetchrow_hashref ) {
        unless ( $field_ok ) {
            croak("Invalid key field: '$key_field'") unless 
                exists $record->{ $key_field };
            $field_ok = 1;
        }
        $return{ $record->{ $key_field } } = $record;
    }

    return \%return;
}

# ----------------------------------------------------------------
sub fh {

=pod

=head2 fh

Gets or sets the filehandle of the file being read.

  open my $fh, "<./data.csv";
  $p->fh( $fh );

=cut

    my ( $self, $arg ) = @_;

    if ( defined $arg ) {
        croak("Argument to fh doesn't look like a filehandle")
            unless UNIVERSAL::isa( $arg, 'GLOB' );

        if ( defined $self->{'fh'} ) {
            close $self->{'fh'} or croak("Can't close existing filehandle: $!");
        }

        $self->{'fh'}       = $arg;
        $self->{'filename'} = '';
    }

    if ( !defined $self->{'fh'} && $self->{'filename'} ) {
        my $file = $self->{'filename'};
        open my $fh, "<$file" or croak("Cannot read '$file': $!");
        $self->{'fh'} = $fh;
    }

    return $self->{'fh'};
}

# ----------------------------------------------------------------
sub field_compute {

=pod

=head2 field_compute

A callback applied to the fields identified by position (or field
name if C<bind_fields> or C<bind_header> was called).  

The callback will be passed two arguments:

=over 4

=item 1

The current field

=item 2

A reference to all the other fields, either as an array or hash 
reference, depending on the method which you called.

=back

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

You could write a field_compute like this:

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

=cut

    my $self = shift;

    if ( @_ ) {
        my ( $position, $callback ) = @_;
        croak('No field name or position')   unless defined $position;
        croak('Callback not code reference') unless ref $callback eq 'CODE';
        $self->{'field_computes'}{ $position } = $callback;
    }

    return $self->{'field_computes'} || {};
}

# ----------------------------------------------------------------
sub field_filter {

=pod

=head2 field_filter

A callback which is applied to each field.  The callback will be
passed the current value of the field.  Whatever is passed back will
become the new value of the field.  Here's an example that removes the
leading and trailing spaces from each field:

  $p->field_filter( sub { $_ = shift; s/^\s+|\s+$//g; $_ } );

=cut

    my ( $self, $filter ) = @_;

    if ( $filter ) {
        croak("Argument to field_filter doesn't look like code")
            unless ref $filter eq 'CODE';
        $self->{'field_filter'} = $filter;
    }
    elsif ( defined $filter && $filter eq '' ) {
        $self->{'field_filter'} = '';
    }

    return $self->{'field_filter'} || '';
}

# ----------------------------------------------------------------
sub field_list {

=pod

=head2 field_list

Returns the fields bound via C<bind_fields> (or C<bind_header>).

  $p->bind_fields( qw[ foo bar baz ] );
  my @fields = $p->field_list;
  print join(', ', @fields); # prints "foo, bar, baz"

=cut

    my $self = shift;
    if ( ref $self->{'field_pos_ordered'} eq 'ARRAY' ) {
        return @{ $self->{'field_pos_ordered'} };
    }
    else {
        croak('No fields. Call "bind_fields" or "bind_header" first.');
        return ();
    }
}

# ----------------------------------------------------------------
sub field_positions {

=pod

=head2 field_positions

Returns a hash of the fields and their positions bound via 
C<bind_fields> (or C<bind_header>).

=cut

    my $self = shift;
    return %{ $self->{'field_pos'} || {} };
}

# ----------------------------------------------------------------
sub field_separator {

=pod

=head2 field_separator

Gets and sets the token to use as the field delimiter.  The default is 
a comma.

  $p->field_separator("\t");     # splits fields on tabs
  $p->field_separator('::');     # splits fields on double colons
  my $sep = $p->field_separator; # returns the current separator

=cut

    my $self = shift;
    $self->{'field_separator'} = shift if @_;
    return $self->{'field_separator'} || ',';
}

# ----------------------------------------------------------------
sub filename {

=pod

=head2 filename

Gets or sets the complete path to the file to be read.  If a file is
already opened, then the handle on it will be closed and a new one
opened on the new file.

  $p->filename('/path/to/file.dat');

=cut

    my $self = shift;

    if ( my $filename = shift ) {
        if ( -d $filename ) {
            croak( "Cannot use directory '$filename' as input source" );
        } 
        elsif ( -f _ && -r _ ) {
            if ( my $fh = $self->fh ) {
                close $fh or croak(
                    "Can't close '", $self->{'filename'}, "': $!\n"
                );
                $self->{'fh'} = undef;
            }
            $self->{'filename'} = $filename;
        } 
        else {
            croak(
                "Cannot use '$filename' as input source: ".
                "file does not exist or is not readable."
            );
        }
    }

    return $self->{'filename'} || '';
}

# ----------------------------------------------------------------
sub header_filter {

=pod

=head2 header_filter

A callback applied to column header names.  The callback will be
passed the current value of the header.  Whatever is returned will
become the new value of the header.  Here's an example that collapses
spaces into a single underscore and lowercases the letters:

  $p->header_filter( sub { $_ = shift; s/\s+/_/g; lc $_ } );

=cut

    my ( $self, $filter ) = @_;

    if ( $filter ) {
        croak("Argument to field_filter doesn't look like code")
            unless ref $filter eq 'CODE';
        $self->{'header_filter'} = $filter;

        if ( my %field_pos = $self->field_positions ) {
            my @new_order;
            while ( my ( $field, $order ) = each %field_pos ) {
                my $xform = $filter->( $field );
                $new_order[ $order ] = $xform;
            }

            $self->bind_fields( @new_order );
        }
    }
    elsif ( defined $filter && $filter eq '' ) {
        $self->{'header_filter'} = '';
    }

    return $self->{'header_filter'} || '';
}

# ----------------------------------------------------------------
sub record_separator {

=pod

=head2 record_separator

Gets and sets the token to use as the record separator.  The default is 
a newline ("\n").

To read a file that looks like this:

  field1
  field2
  field3
  // 
  data1
  data2
  data3
  //

Set the record and field separators like so:

  $p->record_separator("\n//\n");
  $p->field_separator("\n");

=cut

    my $self = shift;
    $self->{'record_separator'} = shift if @_;
    return $self->{'record_separator'} || "\n";
}

1;

# ----------------------------------------------------------------
# I must Create a System, or be enslav'd by another Man's; 
# I will not Reason and Compare; my business is to Create.
#   -- William Blake, "Jerusalem"                  
# ----------------------------------------------------------------

=pod

=head1 AUTHOR

Ken Y. Clark E<lt>kclark@cshl.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Ken Y. Clark

This library is free software;  you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please use http://rt.cpan.org/ for reporting bugs.

=cut
