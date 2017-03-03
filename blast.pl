#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw(:config pass_through no_ignore_case no_auto_abbrev);

my ($num_threads, $query, $out, $outfmt, $help) = (1,"","","","");
GetOptions (
  "num_threads:i" => \$num_threads,
  "query=s" => \$query,
  "out=s" => \$out,
  "outfmt:s" => \$outfmt,
  "h|help" => \$help,
);

$out =~ s/\.gz$//;

my $blast_path = "/ncbi-blast-2.6.0+/bin";
my $blast = $0;

die `$blast_path/$blast -help` if $help;

my $blast_args = join(' ',@ARGV);
$blast_args   .= " -outfmt \'$outfmt\'" if $outfmt; #put quotes around -outfmt options

die "ERROR: query file '$query' not found\n" unless my $query_size = -s $query;

my $block_size = int($query_size / $num_threads) + 1;

system "cat $query | parallel -k -j $num_threads --block $block_size --recstart '>' --pipe \"$blast_path/$blast -query - $blast_args\" | gzip > $out.gz";
