#!/usr/bin/perl
#===========File: TermTagDirectory.pl===========
#Title:        TermTagDirectory.pl - Tag a Directory for Terms
#Description:  Tags a directory containing preprocessed data (in the format of TagUnlabeledDataDirectory.pl or PreprocessAnnotatedDataDirectory.pl resultfiles) or plaintext data and optionally evaluates results if a path to the gold standard data is provided.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      28.07.2011.
#Last Changes: 28.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use Encode;
use encoding "UTF-8";
use File::Basename;

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path of this file to places where Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

if (not((defined$ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4]))) #Cheking if all required parematers exist.
{ 
	print "usage: perl TermTagDirectory.pl [ARGS]\nARGS:\n\t1. [Input directory] - directory from which to read files.\n\t2. [Output directory] - directory to which the term-tagged files will be written.\n\t3. [Input extension] - extension of the input files.\n\t4. [Output extension] - extension of the output files.\n\t5. [Property file] - term extraction property file.\n\t6. [Evaluation file] - evaluation file path (optional and\n\t\tonly if test data is passed in the input data).\n\t7. [N-Gram Prioritized or Mixed Tagging Algorithm] - If \"OLD\" or no parameter - prioritized, otherwise - mixed (optional).\n"; die;
}

my $inputDir = $ARGV[0]; #The input directory depending on the "execPosTagger" parameter in the property file may contain either POS-tagged documents or plaintext documents.
$inputDir =~ s/\\/\//g;
if ($inputDir !~ /.*\/$/)
{
	$inputDir .= "/";
}
my $outputDir = $ARGV[1];
$outputDir =~ s/\\/\//g;
if ($outputDir !~ /.*\/$/)
{
	$outputDir .= "/";
}
unless(-d $outputDir){mkdir $outputDir or die "[TermTagDirectory] Cannot find nor create output directory \"$outputDir\".";}
my $inExt = $ARGV[2]; #Has to be without punctuation!
my $outExt = $ARGV[3]; #Has to be without punctuation!
my $propFile = $ARGV[4]; #Full path to a property file.
$propFile =~ s/\\/\//g;
my $evalFile = $ARGV[5];
my $oldTagging = "";
if (defined($ARGV[6]))
{
	$oldTagging = $ARGV[6];
}

#For all files in the input directory - tag terms in the documents.
opendir(DIR, $inputDir) or die "[TermTagDirectory] Can't open directory \"$inputDir\": $!";
while (defined(my $file = readdir(DIR)))
{
	#Use only valid files with the correct extension!
	my $ucFile = uc($file);
	my $ucExt = uc($inExt);
	if ($ucFile =~ /.*\.$ucExt$/)
	{
		my $inFile = $inputDir.$file;
		my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inFile,qr/\.[^.]*/);
		my $outFile = $outputDir.$inputFileName.".".$outExt;
		print STDERR "[TermTagDirectory] Tagging file: $file\n";
		my $res = `perl "$Bin/ExecuteCollTermOnFile.pl" "$inFile" "$outFile" "$propFile" 0 $oldTagging`; #Add one more parameter ("1") if you wish temporary data to be kept...
		print $res;
	}
	else
	{
		#All other files (with the wrong extension) will be left untouched.
		print STDERR "[TermTagDirectory] Skipping file: $file\n";
	}
}

if (defined($ARGV[5]) && $ARGV[5] ne "") #If an evaluation file is specified, the tagged data is evaluated!
{
	#Evaluating the results (comparison of input and output data on a directory).
	print STDERR "[TermTagDirectory] Starting to evaluate results on directories:\n\tGold: $inputDir\n\tTest results: $outputDir\n";
	my $res = `perl "$Bin/TEEvaluation.pl" "$inputDir" "$outputDir" "$evalFile"`;
	print $res;
}

exit;
