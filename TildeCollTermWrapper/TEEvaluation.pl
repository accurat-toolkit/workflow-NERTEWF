#!/usr/bin/perl
#===========File: TEEvaluation.pl===============
#Title:        TEEvaluation.pl - Evaluates the Precision, Recall, Accuracy and F-measure of Term Tagged Data on Gold Standard Data
#Description:  Reads term tags from data files in the first directory (parameter 0) and compares them with term tags from data files in the second directory (parameter 1). The first directory is referred to as the gold standard directory and the second directory is referred to as the test case result directory. The script produces a result file (parameter 2), which contains evaluation (precision, recall, accuracy and f-measure) of the TE system that produced the test results.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      28.06.2011
#Last Changes: 01.08.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Add this path to places where perl is searching for modules.
}
use strict;
use warnings;

my $testDir;
my $answerDir;

#Checking if all required parameters are set.
if(($ARGV[0])&&($ARGV[1])&&($ARGV[2]))
{ 
	$testDir = $ARGV[0];
	$testDir =~ s/\\/\//g; # Normalizes path (for cross platform campatibility).
	if ($testDir !~ /.*\/$/){$testDir .= "/";}
	$answerDir = $ARGV[1];
	$answerDir =~ s/\\/\//g;
	if ($answerDir !~ /.*\/$/){$answerDir .= "/";}
	opendir(TESTDIR,$testDir) or die "can't open dir $testDir: $!"; # Gets file names in folder.
	opendir(ANSWDIR,$answerDir) or die "can't open dir $answerDir: $!";
	open(EVAL, ">:encoding(UTF-8)", $ARGV[2]);
}
else {print STDERR "usage: TEEvaluation.pl [TestFolder] [AnswerFolder] [outfile]\n"; die;}

#%shortNonRelNotRetr  =(
#					[TE token] => [non retrived count] )

my %shortNonRelNotRetr = (    
			"B-TERM" => 0,
			"I-TERM" => 0,
    );

# my $shortNonRelNotRetr =0;
	
	
my $shortTotal = 0;
my $shortAllRelevantRetrieved = 0;
my $shortAllRetrieved = 0;
my $shortAllRelevant = 0;
my $shortAllNonRelNotRetr = 0; 
my %shortRetrieved;
my %shortRelevant;
my %shortRelevantRetrieved;


my $BordersMatch = 0;
my $fullAllRelevantRetrieved = 0;
my $fullAllRetrieved = 0;
my $fullAllRelevant = 0;
my %fullRelevantRetrieved;
my %fullRetrieved ;
my %fullRelevant;


my @answerFiles ;
while (defined(my $answerFile = readdir(ANSWDIR))) #Reads all the tagged data file names in an array.
{
	if (($answerFile ne '.') || ($answerFile ne '.')) { push @answerFiles, $answerFile;}
}


while (defined(my $testFile = readdir(TESTDIR))) #Gets gold data file names.
{

	if( ($testFile eq '.') || ($testFile eq '..') ){ next;}  #Ignores "." or ".." non-file names!
	my $found = 0;
	my $stripedTest = $testFile; #Strips the extension so that file names can be compared.
	$stripedTest =~ s/\.[^\.]+$//;
	
	
	for my $z (0 .. $#answerFiles)  #Iterates through the tagged folder names to find equal file names.
	{

		my $stripedAnsw = $answerFiles[$z];
		$stripedAnsw =~ s/\.[^\.]+$//;
		
		if ($stripedTest eq $stripedAnsw)
		{ 

			if (not(open(TEST, "<:encoding(UTF-8)", $testDir.$testFile ))) { print STDERR  "can't open  $testDir$testFile"; next;}
			if (not(open(ANSWER, "<:encoding(UTF-8)", $answerDir. $answerFiles[$z])))  { print STDERR  "can't open  $testDir$answerFiles[$z]"; next;} 
			
			while (my $answerTokenLine = <ANSWER>)
			{
				my $testTokenLine = "";
				my $isEOF = 0;
				while($answerTokenLine =~ /^\s*$/) {if (not($answerTokenLine = <ANSWER>)) {$isEOF=1;last;} }
				while($testTokenLine =~ /^\s*$/) {if (not($testTokenLine = <TEST>)) {$isEOF=1;last;}}
				if($isEOF) {last;}
				$testTokenLine =~ s/\n//;
				$testTokenLine =~ s/\r//;
				$answerTokenLine =~ s/\n//;
				$answerTokenLine =~ s/\r//;
				
				my @answerToken = split (/\t/,$answerTokenLine);
				my @testToken = split (/\t/,$testTokenLine);
				
				#Both $answerToken[8] and $testToken[8] vales are term tags for respective tokens.
				#Gets the required information for term tag evaluation.
				$shortTotal++;
				
				for my $NEtag (keys %shortNonRelNotRetr)
				{
					if (($answerToken[8] ne $NEtag) && ($testToken[8] ne $NEtag))
					{
						$shortNonRelNotRetr{$NEtag}++;
					}
				}

				
				#If both tokens are tagged as non-term tokens, count them as non-relevant non-retrieved.
				if (($answerToken[8] eq "O") && ($testToken[8] eq "O")) {$shortAllNonRelNotRetr ++;}
				else
				{
					#If the current answer (tagged data) token is a term token, count it as a retrieved value.
					if ($answerToken[8] ne 'O')
					{
						$shortAllRetrieved ++ ;
						#Create a hash value for each term tag and count how many of each term tags are there in answer files (retrived data).
						if (defined  $shortRetrieved{$answerToken[8]}) 
						{
							$shortRetrieved{$answerToken[8]}++;
						}
						else
						{
							$shortRetrieved{$answerToken[8]} = 1;
						}
					}
					
					#If current test (gold data) token has a term tag, count it as a relevant value.
					if ($testToken[8] ne 'O')
					{
						$shortAllRelevant ++;
						#Create a hash value for each term tag and count how many of each term tags are there in test files (relevant data).
						if (defined  $shortRelevant{$testToken[8]})
						{
							$shortRelevant{$testToken[8]}++;
						}
						else
						{
							$shortRelevant{$testToken[8]} = 1;
						}
					}
					
					# If term tags are identical, count relevant retrieved values.
					if ($testToken[8] eq $answerToken[8])
					{
						$shortAllRelevantRetrieved++;
						#Count relevant retrieved value counts for each token also.
						if (defined  $shortRelevantRetrieved{$testToken[8]})
						{
							$shortRelevantRetrieved{$testToken[8]}++;
						}
						else
						{
							$shortRelevantRetrieved{$testToken[8]} = 1;
						}
					}
					
				}
				
				#Gets the required information for full term evaluation.
				
				#Handles the cases where the term tag has begun in previous tokens first.
				if ($BordersMatch)
				{
					#If the term ends at the same position in both files and begins at the same position, count it as a relevant retrieved term.
					if (($answerToken[8] !~ /^I-/ ) && ($testToken[8] !~ /^I-/))
					{ 
						$fullAllRelevantRetrieved++;
						#Change the BordersMatch value to false.
						$BordersMatch = 0;
					}
					#If the term ends in only one of the files, change the BordersMatch value to false.
					if ($answerToken[8] ne $testToken[8]) {$BordersMatch=0;}
				}
				
				#If a new full term starts:
				if ($answerToken[8] =~ /B-/)
				{
					$fullAllRetrieved++;
					#Saves the count of each full retrieved term tag.
				}	
				
				if ($testToken[8] =~ /B-/)
				{
					$fullAllRelevant++;
					if ($testToken[8] eq $answerToken[8]) #Set the borders to matching if in both files beginning term tokens match.
					{
					   $BordersMatch = 1; 
					}
				}
			
				
			}
			close TEST;
			close ANSWER;

		}
	}
}

if($shortTotal == 0) {die "TEEvaluation.pl: No tokens found!\n";}


#Full term tag evaluation.
my $fullRecall;
my $fullPrecision;
my $fullF1= "-";
#Handles cases when there are no relevant values separately to avoid division by zero.
if($fullAllRelevant == 0) 
{
	$fullRecall = '-';
}
else
{ 
	#Calculates recall.
	$fullRecall =  sprintf("%.2f", ($fullAllRelevantRetrieved/$fullAllRelevant)*100);
} 
#Handles cases when there are no retrieved values separately to avoid division by zero.
if($fullAllRetrieved == 0) 
{
	$fullPrecision = '-';
}
else
{
	#Calculates precision.
	$fullPrecision =  sprintf("%.2f", ($fullAllRelevantRetrieved/$fullAllRetrieved)*100);
}

#Handles cases when there are no relevant or retreved values separately to avoid division by zero.
if (($fullPrecision ne '-')  && ($fullRecall ne '-') )
{
	if (($fullPrecision != 0)  || ($fullRecall != 0) )
	{
		#Calculates F-measure.
		$fullF1 = sprintf("%.2f", ( ($fullPrecision*$fullRecall)*2/($fullPrecision+$fullRecall) ));
	}
}

#Prints calculated numbers in the result file.
print EVAL "FULL_TERMS\t".$fullRecall."\t".$fullPrecision."\t-\t".$fullF1."\n";



#Caculates term token evaluation values.

my $allRecall;
my $allPrecision;
my $allAccuracy;
my $allF1 = "-";

#Handles cases when there are no relevant values separately to avoid division by zero.
if($shortAllRelevant == 0) 
{
	$allRecall = '-';
}
else
{ 
	#Calculates recall.
	$allRecall =  sprintf("%.2f", ($shortAllRelevantRetrieved/$shortAllRelevant)*100);
} 
#Handles cases when there are no retrieved values separately to avoid division by zero.
if($shortAllRetrieved == 0) 
{
	$allPrecision = '-';
}
else
{
	#Calculates precision.
	$allPrecision =  sprintf("%.2f", ($shortAllRelevantRetrieved/$shortAllRetrieved)*100);
}
#Calculates accuracy.
$allAccuracy = sprintf("%.2f", ( ($shortAllRelevantRetrieved + $shortAllNonRelNotRetr)/$shortTotal)*100 );

#Handles cases when there are no relevant or retrieved values separately to avoid division by zero.
if (($allPrecision ne '-')  && ($allRecall ne '-') )
{
	if (($allPrecision != 0)  && ($allRecall != 0) )
	{
		#Calculates F-measure.
		$allF1 = sprintf("%.2f", ( ($allPrecision*$allRecall)*2/($allPrecision+$allRecall) ));
	}
}

#Prints recall, precision, accuracy and F-measure.
print EVAL "TERM_TOKENS\t".$allRecall."\t".$allPrecision."\t".$allAccuracy."\t".$allF1."\n";


#Calculates recall, precision, accuracy and F-measure for each of term token types separately.
#Uses %shortNonRelNotRetr keys to iterate through all possible term tokens.
for my $NETag (keys %shortNonRelNotRetr)
{
	my $relevantRetrieved;
	my $relevant;
	my $retrieved;
	my $recall;
	my $precision;
	my $accuracy;
	my $F1= "-";
	#If hash value doesn't exist, sets the value to '0'.
	if (defined $shortRelevantRetrieved{$NETag})
	{
		$relevantRetrieved = $shortRelevantRetrieved{$NETag};
	}
	else 
	{
		$relevantRetrieved = 0;
	}
	
	if (defined $shortRelevant{$NETag})
	{
		$relevant = $shortRelevant{$NETag};
	}
	else 
	{
		$relevant = 0;
	}
	
	if (defined $shortRetrieved{$NETag})
	{
		$retrieved = $shortRetrieved{$NETag};
	}
	else 
	{
		$retrieved = 0;
	}
	
	if($relevant == 0) 
	{
		$recall = '-';
	}
	else
	{ 
		$recall =  sprintf("%.2f", ($relevantRetrieved/$relevant)*100);
	} 

	if($retrieved == 0) 
	{
		$precision = '-';
	}
	else
	{
		$precision =  sprintf("%.2f", ($relevantRetrieved/$retrieved)*100);
	}
	
	$accuracy = sprintf("%.2f", ( ($relevantRetrieved + $shortNonRelNotRetr{$NETag})/$shortTotal)*100 );
	
	if (($precision ne '-')  && ($recall ne '-') )
	{
		if (($precision != 0)  && ($recall != 0) )
		{
			$F1 = sprintf("%.2f", ( ($precision*$recall)*2/($precision+$recall) ));
		}
	}

	
	print EVAL $NETag."\t".$recall."\t".$precision."\t".$accuracy."\t".$F1."\n";
}



close EVAL;