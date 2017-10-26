#!/usr/bin/perl
#=========File: ExecuteCollTermOnFile.pl==========
#Title:        ExecuteCollTermOnFile.pl - Execute Term Extraction on a File
#Description:  Executes term extraction on a file and produces a marked plaintext document.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      26.07.2011.
#Last Changes: 26.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use File::Basename;
use Encode;
use encoding "UTF-8";

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path of this file to places where Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

#Include toolkit modules for data preprocessing.
use Tag;
use TEUtilities;
use TEPostprocess;

if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2]))) # Cheking if required parematers exist.
{
	print "usage: perl .\ExecuteCollTermOnFile.pl [ARGS]\nARGS:\n\t1. [Input file] - file to tag.\n\t2. [Output file] - file where results will be written.\n\t3. [Property file] - Term extraction property file.\n\t4. [Keep temp files] - If \"1\" temp files will be kept, otherwise - deleted.\n\t5. [N-Gram Prioritized or Mixed Tagging Algorithm] - If \"OLD\" or no parameter - prioritized, otherwise - mixed.\n"; die;
}
my $inputFile = $ARGV[0]; #The input plaintext path.
$inputFile =~ s/\\/\//g;
my $outputFile = $ARGV[1]; #The output marked plaintext path.
$outputFile =~ s/\\/\//g;
my $propFile = $ARGV[2]; #The term extraction property file path.
$propFile =~ s/\\/\//g;

#Read the property file.
my %propHash = TEUtilities::ReadPropertyFile($propFile);

#Read and validate the POS-tagger parameters.
my $executePOSTagger = $propHash{"execPosTagger"};
my $PosTaggerLang = $propHash{"Language"};
my $POSTaggerCode = $propHash{"POSTagger"};
if (defined($executePOSTagger) && $executePOSTagger eq "true")
{
	if (!(defined($PosTaggerLang)&&defined($POSTaggerCode)))
	{
		print "[ExecuteCollTermOnFile] Cannot find \"POSTagger\" or \"Language\" properties in the property file.\n"; die;
	}
}
print STDERR "[ExecuteCollTermOnFile] Starting to process plaintext in \"$inputFile\"\n";

#Split output file to get the directory, file name and extension separated.
my ($outputFileName,$outputFilePath,$outputFileSuffix) = fileparse($outputFile,qr/\.[^.]*/);
my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inputFile,qr/\.[^.]*/);
#Create the temp file directory if non-existing.
unless(-d  $outputFilePath."data/"){mkdir  $outputFilePath."data/" or die "[ExecuteCollTermOnFile] Cannot find nor create output directory \"$outputFilePath"."data\".";}
my $posTaggedFile = $outputFilePath."data/".$outputFileName.".pos";
my $posTermTaggedFile = $outputFilePath."data/".$outputFileName.".pos_t";
my $termTaggedFile = $outputFilePath."data/".$outputFileName.".t";

print STDERR "[ExecuteCollTermOnFile] POS tagging with the tagger \"$POSTaggerCode\" and language \"$PosTaggerLang\". The output will be saved in \"$posTaggedFile\".\n";
#POS tag the plaintext according to the specified tagger and language. Deletes temporary files.
if (defined($executePOSTagger) && $executePOSTagger eq "true")
{
	Tag::TagText($PosTaggerLang, $POSTaggerCode, $inputFile, $posTaggedFile, "1", "1");
}
else
{
	$posTaggedFile = $inputFile;
}
my $maxLen = 4;
#Check whether the POS tagging was successful.
if (-e $posTaggedFile)
{
	#A one dimensional array containing Termex result file paths for different n-grams.
	my @candidateFileArray;
	#A one dimensional array containing n-gram lambda weights for tagging purposes.
	my @lambdaArray;
	#Iteratively acquire different N-gram terms using CollTerm.
	for (my $i = $maxLen; $i>0; $i--)
	{
		#Check whether the particular N-gram terms should be extracted.
		if (defined $propHash{"exec".$i} && $propHash{"exec".$i} eq "true")
		{
			#Read all required CollTerm properties.
			my $idfStr = $propHash{"idfFile".$i};
			my $len = $propHash{"len".$i};
			my $method = $propHash{"method".$i};
			my $threshold = $propHash{"threshold".$i};
			my $stopWordList = $propHash{"stop".$i};
			my $phraseTable = $propHash{"phrase".$i};
			my $positionTable = $propHash{"pos".$i};
			my $minFreq = $propHash{"minFreq".$i};
			my $newTaggedFile = $termTaggedFile.$i;
			if (defined($len)&&defined($method)&&defined($threshold)&&defined($phraseTable)&&defined($positionTable)&&defined($minFreq)&&defined($idfStr))
			{
				print STDERR "[ExecuteCollTermOnFile] Starting to tag terms using the property file \"$propFile\". The results will be saved in \"$newTaggedFile\"\n";
				#Execute CollTerm with or without a stopword list.
				if ($^O eq "MSWin32")
				{
					if (defined ($stopWordList) && $stopWordList ne "")
					{
						#There are strange differences on how python can be installed on Windows. For some machines the "python" alias has to be used, but for some not, therefore we try to do both ...
						my $res = `"$Bin/collterm_0.7.py" -pos $positionTable -l $len -m $method -p "$phraseTable" -s "$stopWordList" -i "$posTaggedFile" -o "$newTaggedFile" -min $minFreq -idf $idfStr`;
						if (not (defined $res && -e $newTaggedFile))
						{
							$res = `python "$Bin/collterm_0.7.py" -pos $positionTable -l $len -m $method -p "$phraseTable" -s "$stopWordList" -i "$posTaggedFile" -o "$newTaggedFile" -min $minFreq -idf $idfStr`;
						}
						print $res;
					}
					else
					{
						my $res = `"$Bin/collterm_0.7.py" -pos $positionTable -l $len -m $method -p "$phraseTable" -i "$posTaggedFile" -o "$newTaggedFile" -min $minFreq -idf $idfStr`;
						if (not (defined $res && -e $newTaggedFile))
						{
							$res = `python "$Bin/collterm_0.7.py" -pos $positionTable -l $len -m $method -p "$phraseTable" -i "$posTaggedFile" -o "$newTaggedFile" -min $minFreq -idf $idfStr`;
						}
						print $res;
					}
				}
				else
				{
					if (defined ($stopWordList) && $stopWordList ne "")
					{
						my $res = `python "$Bin/collterm_0.7.py" -pos $positionTable -l $len -m $method -p "$phraseTable" -s "$stopWordList" -i "$posTaggedFile" -o "$newTaggedFile" -min $minFreq -idf $idfStr`;
						print $res;
					}
					else
					{
						my $res = `python "$Bin/collterm_0.7.py" -pos $positionTable -l $len -m $method -p "$phraseTable" -i "$posTaggedFile" -o "$newTaggedFile" -min $minFreq -idf $idfStr`;
						print $res;
					}
				}
				#If the term list is created, apply a threshold on the extracted terms.
				if (-e $newTaggedFile)
				{
					TEUtilities::ApplyTermThreshold($newTaggedFile,$newTaggedFile."_t",$threshold);
					push @candidateFileArray, $newTaggedFile."_t";
					push @lambdaArray, $propHash{"lambda".$i};
				}
				else
				{
					print STDERR "[ExecuteCollTermOnFile] Execution of CollTerm failed. The result file \"$newTaggedFile\" cannot be found.\n";
				}
			}
			else
			{
				print STDERR "[ExecuteCollTermOnFile] Execution of CollTerm failed. The result file \"$newTaggedFile\" cannot be found.\n";
			}
		}
	}
	my $numberOfFiles = @candidateFileArray;
	if ($numberOfFiles>0)
	{
		#If at least one N-gram term list file was created, tag terms in the POS-tagged file.
		if (!(defined($executePOSTagger) && $executePOSTagger eq "true"))
		{
			$posTermTaggedFile = $outputFile;
		}
		if (!defined($ARGV[4]) || $ARGV[4] eq "OLD" || $ARGV[4] eq "")
		{
			print STDERR "[ExecuteCollTermOnFile] Using the n-gram prioritization tagging algorithm.\n";
			TEPostprocess::TagTermsFromMultipleFiles($posTaggedFile, \@candidateFileArray, $posTermTaggedFile);
		}
		else
		{
			print STDERR "[ExecuteCollTermOnFile] Using the ranked tagging algorithm.\n";
			TEPostprocess::TagTermsFromMultipleFilesV2($posTaggedFile, \@candidateFileArray, \@lambdaArray, $posTermTaggedFile);
		}
		if (-e $posTermTaggedFile && defined($executePOSTagger) && $executePOSTagger eq "true")
		{
			#If the term-tagged and POS-tagged file is created, apply markup to the plaintext.
			TEPostprocess::TaggedTokensToTaggedPlaintext($posTermTaggedFile, $inputFile, $outputFile);
		}
		elsif (!(-e $posTermTaggedFile))
		{
			print STDERR "[ExecuteCollTermOnFile] Term extraction failed as combination of the term list files and the POS-tagged file failes. File \"$posTermTaggedFile\" is missing.\n";
		}
	}
	else
	{
		print STDERR "[ExecuteCollTermOnFile] Term extraction failed as no output files after CollTerm call were created.\n";
	}
}
else
{
	print STDERR "[ExecuteCollTermOnFile] File \"$posTaggedFile\" is missing.\n";
}

#If not explicitly defined, POS Tagging temp files are deleted.
if (!defined($ARGV[3]) || $ARGV[3] ne "1")
{
	for (my $i = $maxLen; $i>0; $i--)
	{
		my $newTaggedFile = $termTaggedFile.$i;
		unlink ($newTaggedFile);
		unlink ($newTaggedFile."_t");
	}
	if ($posTaggedFile ne $inputFile)
	{
		unlink ($posTaggedFile);
	}
	if ($posTermTaggedFile ne $outputFile)
	{
		unlink ($posTermTaggedFile);
	}
	rmdir ($outputFilePath."data/");
}
exit;