#!/usr/bin/perl

#
# test for "new"
#

use strict;
use Test::More tests => 17;
use FindBin '$Bin';

require_ok( 'Text::RecordParser' );

#
# Vanilla "new," test defaults
#
{
    my $p = Text::RecordParser->new;
    isa_ok( $p, 'Text::RecordParser' );

    is( $p->filename, '', 'Filename is blank' );
    is( $p->fh, undef, 'Filehandle is undefined' );
    is( $p->field_filter, '', 'Field filter is blank' );
    is( $p->header_filter, '', 'Header filter is blank' );
    is( $p->field_separator, ',', 'Default separator is a comma' );
    is( $p->trim, undef, 'Default trim value is undefined' );
}

#
# New with arguments
#
{
    my $file = "$Bin/data/simpsons.csv";
    my $p    = Text::RecordParser->new($file);
    is( $p->filename, $file, "Filename set to '$file'" );
}

{
    my $file             = "$Bin/data/simpsons.csv";
    my $p                = Text::RecordParser->new(
        filename         => $file,
        field_separator  => "\t",
        record_separator => "\n\n",
        field_filter     => sub { $_ = shift; s/ /_/g; $_ },
        header_filter    => sub { $_ = shift; s/\s+/_/g; lc $_ },
        trim             => 1,
    );

    is( $p->filename, $file, "Filename set to '$file'" );
    is( $p->field_separator, "\t", 'Field separator is a tab' );
    is( $p->record_separator, "\n\n", 'Record separator is two newlines' );
    is( ref $p->field_filter, 'CODE', 'Field filter is code' );
    is( ref $p->header_filter, 'CODE', 'Header filter is code' );
    is( $p->trim, 1, 'Trim mode is on' );
}

#
# New with too many arguments
#
{
    my $p;
    eval {
        $p           = Text::RecordParser->new(
            filename => "$Bin/data/simpsons.csv",
            data     => "foo\tbar\tbaz",
        );
    };
    my $err = $@;

    is( $p, undef, 'Did not create parser...' );
    like( $err, qr/too many arguments/, '...because too many args' );
}
