#!/usr/bin/perl
#===========File: PrepareTEData.pl===============
#Title:        PrepareTEData.pl - Preprocess a Term Annotated Plaintext Document for CollTerm Testing.
#Description:  POS tags a term annotated plaintext document and produces output data in a tokenized tab-separated format including term tags.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 29.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
use strict;
use warnings;


 BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Add this path to places where perl is searching for modules.
}
#Checking if all required parameters are set.
if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])))
{ 
	print STDERR  "usage perl PrepareTEData.pl [ARGS]\nARGS:\n\t1. [Language] - The tagger language (en|lv|et..).\n\t2. [POS Tagger] - The POS tagger to use (POS|Tree|Tagger).\n\t3. [Input File] - the path to the input file.\n\t4. [Output File] - The path to the output file\n\t5. [Delete temp files] - \"-D\" to delete temporary files (optional).\n";
	die;
}


my $FullIputfilename = $ARGV[2];

#Defines the location where to write temporary files.
my	$outputDir = $ARGV[3]; 
if ($outputDir =~ /[\\\/]/)
{
	$outputDir =~ s/\\/\//gi;
	$outputDir =~ s/\/[^\/]+$//g;
	$outputDir .= "\/data\/";
}
else
{
$outputDir = "data\/";
}
#Creates temp data directory if it does not exist.
unless(-d $outputDir){mkdir $outputDir or die "[PrepareTEData] Cannot find nor create output directory \"$outputDir\".";}

use TEPreprocess;
 
my  $Iputfilename = $FullIputfilename;
$Iputfilename=~ s/(.*)(\.[^\.]+$)/$1/g;
$Iputfilename=~ s/\\/\//gi;
$Iputfilename=~ s/.*\/([^\/]+)/$1/g;

my $del =0;	

 if($ARGV[4]) #Specifies, whether to delete temporary data files.
{ 
	 if($ARGV[4] eq "-D")
	{	
		$del=1;
	}
}
#Splitting tags and plaintext in two separate documents.
TEPreprocess::Detagger( "$FullIputfilename", "$outputDir$Iputfilename.plain", "$outputDir$Iputfilename.tags",); 

use Tag;

my $pie;
#POS-tags the plaintext document.
Tag::TagText($ARGV[0],$ARGV[1], "$outputDir$Iputfilename.plain", "$outputDir$Iputfilename.POS",$del,1);

#Combines the term tags with the POS-tagged document
TEPreprocess::AddNewTags( "$outputDir$Iputfilename.POS", "$outputDir$Iputfilename.tags" , "$ARGV[3]", "1" );

#Deletes the temporary files and the temporary directory if required.
if($del)
{

	 unlink ("$outputDir$Iputfilename.plain");
	 unlink ("$outputDir$Iputfilename.taggs");
	 unlink ("$outputDir$Iputfilename.POS");
	 unlink ("$outputDir$Iputfilename.tags");
	 rmdir ("$outputDir");
}

exit;
