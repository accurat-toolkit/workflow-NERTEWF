#!/usr/bin/perl
#======File: ExecuteCollTermOnFileList.pl=======
#Title:        ExecuteCollTermOnFileList.pl - Term Extraction of Plaintext Files using CollTerm.
#Description:  Tags UTF-8 encoded plaintext (execPosTagger property equals to "true") or pre-processed (execPosTagger property equals to "false") documents from a list file for terms and adds term tags within the plaintext documents (execPosTagger property equals to "true").
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      17.08.2011.
#Last Changes: 17.08.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use File::Basename;
use Encode;
use encoding "UTF-8";

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path to places whre Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

if (not(defined($ARGV[0])&&defined($ARGV[1]))) # Cheking if required parematers exist.
{ 
	print "usage: perl ExecuteCollTermOnFileList.pl [ARGS]\nARGS:\n\t1. [Input file pair list] - files to tag in a tab-separated document.\n\t2. [Property file] - Term extraction property file.\n"; die;
}

my $inputFileList = $ARGV[0]; #The input plaintext file list (one pair contains input and output files - tab separated).
$inputFileList =~ s/\\/\//g;
my $propFile = $ARGV[1]; #The term extraction property file.
$propFile =~ s/\\/\//g;
if (-e $inputFileList)
{
	print STDERR "[ExecuteCollTermOnFileList] Starting to process plaintext documents from \"$inputFileList\"\n";
	open(INFILE, "<:encoding(UTF-8)", $inputFileList);
	while (<INFILE>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if ($line ne "" && $line !~ /#.*/)
		{
			my ($sourceFile, $targetFile) = split(/\t/, $line, 2);
			$sourceFile =~ s/^\s+//;
			$sourceFile =~ s/\s+$//;
			$targetFile =~ s/^\s+//;
			$targetFile =~ s/\s+$//;
			if (defined ($sourceFile) && defined ($targetFile))
			{
				my $res = `perl "$Bin/ExecuteCollTermOnFile.pl" "$sourceFile" "$targetFile" "$propFile"`;
				print $res;
			}
		}
	}
}
else
{
	print STDERR "[ExecuteCollTermOnFileList] File \"$inputFileList\" is missing. Term-tagging aborted.\n";
}
close INFILE;
