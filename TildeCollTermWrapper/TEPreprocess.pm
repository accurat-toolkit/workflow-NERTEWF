#!/usr/bin/perl
#===========File: TEPreprocess.pm===============
#Title:        TEPreprocess.pm - Data Pre-processing Module for Tilde's Wrapper System for CollTerm.
#Description:  The Module contains data pre-processing methods for term tagging.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 01.08.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

package   TEPreprocess;

use strict;
use warnings;

#===========Method: RemoveEmptyLines============
#Title:        RemoveEmptyLines
#Description:  Removes empty lines according to the option (argument 2) from the input file (argument 0) and saves the output to the output file (argument 1). Options are: "1" - keep all empty lines, "2" - keep all lines, where 2 or more empty lines are one after another, everything else removes all lines.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      07.06.2011.
#Last Changes: 08.06.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub RemoveEmptyLines
{
	#Checking if all required parameters are set.
	if (defined($_[0])&&defined($_[1])&&defined($_[2]))
	{ 
		open(IN, "<:encoding(UTF-8)", $_[0]);
		open(OUT, ">:encoding(UTF-8)", $_[1]);
	}
	else {print STDERR "Usage: RemoveEmptyLines [Input file] [Output file] [Option]\nOptions:\n\t1 - keep all empty lines;\n\t2 - keep only those empty lines where two or more empty lines are one after another;\n\teverything else removes all empty lines."; die;}
	my $option = $_[2];

	my $emptyCount = 0;
	while (<IN>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; #Strips BOM.
		$line =~ s/\n//;
		$line =~ s/\r//;
		if ($line eq "") #Count up subsequent empty lines.
		{
			$emptyCount++;
		}
		else
		{
			#Print out all empty lines if option "1" is selected.
			#Print out all empty lines where two or more subsequent empty lines are present and option "2" is selected.
			if ($option eq "1" || ($emptyCount>1 && $option eq "2"))
			{
				while ($emptyCount>0)
				{
					print OUT "\n";
					$emptyCount--;
				}
			}
			$emptyCount=0;
			print OUT $line."\n";
		}
	}
	close IN;
	#Print the trailing empty lines according to the options (see above).
	if ($option eq "1" || ($emptyCount>1 && $option eq "2"))
	{
		while ($emptyCount>0)
		{
			print OUT "\n";
			$emptyCount--;
		}
	}
	close OUT;
}

#=========Method: Detagger==========
#Title:        Detagger
#Description:  Processes term tagged text (argument 0) file and creates two result files - a plaintext file (argument 1), which does not contain term tags, and a file (argument 2), which contains only term tags and their positions within the plaintext.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      July, 2011.
#Last Changes: 01.08.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub Detagger 
{ 
	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1])&&defined($_[2]))
	{ 
		open(FIN, "<:encoding(UTF-8)", $_[0]);
		open(PLAIN, ">:encoding(UTF-8)", $_[1]);
		open(TAGGS, ">:encoding(UTF-8)", $_[2]);
	}
	else {print STDERR "usage: detagger [InputText] [OutPlain] [OutTaggs]\n"; die;}
	
	my $file;
	my $line=0; 
	my @taggs;
	#Read all lines from the term tagged file.
	while (<FIN>){ 
		$file = $_;
		$file =~ s/^\x{FEFF}//; # Removes BOM if present.
		my $TagLen;
		my $tag;
		my $tagType;
		my $taggStart;
		while( $file =~ /<TENAME>/g) #Finds tag beginnings.
		{
			$TagLen= 8; #Gets the tag length.
			$tag="TENAME";
			#Saves additional information about the tag. This information contains the tag type.
			$tagType=$2;
			#Gets tag position (equals to tag length subtracted from current position after finding a match).
			my $start = pos($file) - $TagLen;
			
			substr($file, $start,$TagLen) = ''; #Deletes the tag in the string 'file' (containing only plaintext at the end).
			my $end;
			
			if ($file =~ /(<\/$tag>)/g) #Finds the ending tag.
			{
				$end= pos($file) - length $1;
				substr($file, $end,length $1) = ''; #Removes the ending tag to get plaintext in the string 'file'
				my @tag = ("TERM",$line,$start,$line,$end-1);
				push @taggs, [@tag];
				if ($file =~ /^\s*$/){last;}
			}
			else #In the case when the ending tag is not in the same line, increase the line and continue searching(should not happen, but theoretically can).
			{
				my $line2= $line ; #Finds the end line number.
				while (not($file =~ /(<\/$tag>)/g))
				{
					$line2 += 1;
					print PLAIN $file; #Print the line of plaintext before reading a new one.
					if(not($file = <FIN>)) #If can't find end tag print a warning, but continue (should not happen, but theoretically can).
					{
						print STDERR "Warning: File contains a tag that was not closed\nUnknown program behavior\n";
						last;
					}
				}
				
				$end= pos($file) - (length($tag) + 3); #Get the end position (equals to tag length +3 because it consists of tag name and 3 symbols - "</>").
				my $len = length($tag) + 3;
			
				substr($file, $end,$len) = '';
				print STDERR " tag tipe -  $tagType, start line - $line $start, end- $line2 ".($end-1)."\n"; #Warn that a tag spans two or more lines.
				$line= $line2;
			}
		}
		$line += 1;
		print PLAIN $file;  #Prints the text with removed tags in the plaintext file.
	}
	for my $i ( 0 .. $#taggs ) #Print the tags in the tag file.
	{
		print TAGGS "$taggs[$i][0]\t$taggs[$i][1]\t$taggs[$i][2]\t$taggs[$i][3]\t$taggs[$i][4]\n";
	}
	close FIN;
	close PLAIN;
	close TAGGS;
}

#=========Method: AddNewTags==========
#Title:        AddNewTags
#Description:  Processes a tokenized and POS-tagged text file (argument 0) and a term tag file (argument 1) to add term tags to POS tags where their positions match and writes the results in a file (argument 2).
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      July, 2011.
#Last Changes: 01.08.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub AddNewTags 
{ 
	# use Switch;
	my $printEmptyLines = $_[3]; # If "1" - prints all lines; if "2" - prints only those, where more than one is present (Keeping one paragraph together!), otherwise does not print any empty lines.
	
	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1]) && defined($_[2]))
	{ 
		open(POSTAGGS, "<:encoding(UTF-8)", $_[0]);
		open(TETAGGS, "<:encoding(UTF-8)", $_[1]);
		open(OUT, ">:encoding(UTF-8)", $_[2]);
	}
	else {print STDERR "usage: AddNewTaggs [POSTaggFile] [TETaggFile] [outfile]\n"; die;}

	my @TEtaggs;
	my @POStaggs;
	my $Fileline; 
	my $POSLine;
	while( <TETAGGS>)
	{
		$Fileline = $_;
		$Fileline =~ s/\n//;
		$Fileline =~ s/\r//;
		if ($Fileline=~ /^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$/) # Gets term tags from file into an array
		{
					my @TEtagg = ($1,$2,$3,$4,$5,"B"); # $1 - term tag $2 - starting line $3 - starting position $4 - end line $5 - end position 
					push @TEtaggs, [@TEtagg];
		}
	}
	
	my %emptyLineHash;
	my $currentTagLine=0;
	#Reads all tokens and their information.
	while(<POSTAGGS>)
	{
		$POSLine = $_;
		$POSLine =~ s/\n//;
		$POSLine =~ s/\r//;
		
		#Gets POS tags from the POS-tagged file into an array. The tab-separated format is strict as FindTokenPos should have been used on files using different POS-taggers before.
		if ($POSLine=~ /^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+)$/)  
		{
			my @POStagg = ($1,$2,$3,$4,$5,$6,$7,$8,"O"); # $1 - token $2 - POS tag $3 - lemma $4 - Morphological tag $5 - starting line $6 - starting position $7 - end line $8 - end position	"O" - empty term tag
			push @POStaggs, [@POStagg];
			$currentTagLine++;
		}
		else
		{
			#Counts the amount of empty lines before the next non-empty line and fills the hash table with the amounts assigned to the non-empty line.
			if (defined $emptyLineHash{ $currentTagLine })
			{
				$emptyLineHash{$currentTagLine}++;
			}
			else
			{
				$emptyLineHash{$currentTagLine}=1;
			}
		}
	}
	
	#Iterates trough POS tags.
	for my $i ( 0 .. $#POStaggs )
	{
		if ($printEmptyLines eq "1" && defined $emptyLineHash{ $i }) #Prints all empty lines.
		{
			for my $el (1 .. $emptyLineHash{ $i })
			{
				print OUT "\n";
			}
		}
		elsif ($printEmptyLines eq "2" && defined $emptyLineHash{ $i } && $emptyLineHash{ $i }>1) #Prints only those empty lines, which are more than 1 in a row of the POS tagged file.
		{
			for my $el (1 .. $emptyLineHash{ $i })
			{
				print OUT "\n";
			}
		}
		for my $j ( 0 .. $#TEtaggs ) 
		{
			my @TempPOStaggs;
			my $int = 0; #The number of tokens already tagged in a term.
			my $Start; #The original starting position of an term.
			my $StartLin ;
			if($TEtaggs[$j][5] ne "ok") #Ignore term tag if it is already combined with the POS tagged tokens.
			{
				#Tries to match the token starting positions with term tag starting positions.
				while (($TEtaggs[$j][1] == $POStaggs[$i + $int][4]) && ($TEtaggs[$j][2] == $POStaggs[$i + $int][5])) 
				{
					my $tag = $TEtaggs[$j][0]; #Gets the short term tag name according to the full term tag name.
					if($tag) 
					{
						push (@TempPOStaggs, $TEtaggs[$j][5].'-'.$tag); #Puts the term tag at the end of POS tagged tokens
						
						#Saves the starting position of the term Tag.
						if($TEtaggs[$j][5] eq "B") { $Start = $TEtaggs[$j][1]; $StartLin = $TEtaggs[$j][2];} 
						
						#Changes the term tag starting position to the next token if not larger than term tag end position.
						if (($TEtaggs[$j][3] ==  $POStaggs[$i + $int][6]) && ($TEtaggs[$j][4] > $POStaggs[$i + $int][7]) 
						 || ($TEtaggs[$j][3] >  $POStaggs[$i + $int][6]))
						{
							$TEtaggs[$j][1] = $POStaggs[$i+1 + $int][4]; 
							$TEtaggs[$j][2] = $POStaggs[$i+1 + $int][5];
						}
						#Changes the term tag value so that the next tokens in the same term would receive the middle tag prefix.
						$TEtaggs[$j][5]="I";
						
						#If all tokens in the term tag have been tagged save the changes in the array.
						if(($TEtaggs[$j][3] == $POStaggs[$i + $int][6]) && ($TEtaggs[$j][4] == $POStaggs[$i + $int][7])) 
						{
							for my $g ( 0 .. $#TempPOStaggs )
							{
								$POStaggs[$i+$g][8] = $TempPOStaggs[$g];
							}
							$int = 0;
							undef (@TempPOStaggs);
							$TEtaggs[$j][5]="ok";
							last;
						}
						#If a mismatch occurs between token and term boundaries save the term tag positions and exit the loop.
						if (($TEtaggs[$j][3] == $POStaggs[$i + $int][6]) && ($TEtaggs[$j][4] < $POStaggs[$i + $int][7]) 
						|| ($TEtaggs[$j][3] < $POStaggs[$i + $int][6])) 
						{
							#Puts the correct starting positions.
							$TEtaggs[$j][1]  = $Start; 
							$TEtaggs[$j][2] = $StartLin;
							$int = 0;
							undef (@TempPOStaggs);
							last;
						}
					}
					$int = $int + 1; 
				}
			}
		}
		#Prints the fully tagged token.
		print OUT  "$POStaggs[$i][0]\t$POStaggs[$i][1]\t$POStaggs[$i][2]\t$POStaggs[$i][3]\t$POStaggs[$i][4]\t$POStaggs[$i][5]\t$POStaggs[$i][6]\t$POStaggs[$i][7]\t$POStaggs[$i][8]\n";
	}
	
	if ($printEmptyLines eq "1" && defined $emptyLineHash{ $currentTagLine })
	{
		for my $el (1 .. $emptyLineHash{ $currentTagLine })
		{
			print OUT "\n"; #Print trailing empty lines at the end of the document.
		}
	}
	elsif ($printEmptyLines eq "2" && defined $emptyLineHash{ $currentTagLine } && $emptyLineHash{ $currentTagLine }>1) #Prints only those trailing empty lines, which are more than 1 in a row of the POS tagged file.
	{
		for my $el (1 .. $emptyLineHash{ $currentTagLine })
		{
			print OUT "\n";
		}
	}
	
	my $err = 0;
	for my $i ( 0 .. $#TEtaggs ) #Prints term tags that are not added to tokens because of position mismatch.
	{
		if($TEtaggs[$i][5] ne "ok")
		{
			if($err == 0) { print STDERR "Warning: token positions not matching term taggs:\n" }
			$err++;
			print STDERR "$TEtaggs[$i][0]\t$TEtaggs[$i][1]\t$TEtaggs[$i][2]\t$TEtaggs[$i][3]\t$TEtaggs[$i][4]\t$TEtaggs[$i][5]\n";
		}
	}
	close POSTAGGS;
	close TETAGGS;
	close OUT;
}

#=============Method: FindTokenPos==============
#Title:        FindTokenPos
#Description:  Processes a tokenized POS tagged file (argument 0) without token positions and a plaintext file (argument 1) to add positions to POS-tagged tokens. Results are written in a file (argument 3).
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      July, 2011.
#Last Changes: 11.11.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub FindTokenPos
{
	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1])&&defined($_[2]))
	{ 
		open(PLAIN, "<:encoding(UTF-8)", $_[0]);
		open(TOKENS, "<:encoding(UTF-8)", $_[1]);
		open(OUT, ">:encoding(UTF-8)", $_[2]);
	}
	else {print STDERR "usage: FindTokenPos [PaintexFile] [TreetaggedFile] [outfile]\n"; die;}

	my $plain;
	my $line=0;
	while (<PLAIN> )
	{
		$plain = $_;
		$plain =~ s/\x{FEFF}//; # Strips BOM symbol.
		if($plain =~ /^\s*$/) {	$line +=1; next;} #If empty (no tokens) skip to next line.
		my $postion=0;
		while (<TOKENS>)
		{
			my $token =$_;
			$token =~ s/\n//;
			$token =~ s/\r//;
			$token =~ s/^\x{FEFF}//; # Strips BOM symbol.
			if ($token=~/^\s+$/){ print OUT "\n"; next;} #Skip if token is empty.
			#Gets the word and stores other information in $2, $3, etc. variables.
			if (not($token =~ s/^([^\t]+)\t([^\t]+)\t([^\t]+)(.*)$/$1/g)) {next;}
			my $tag = $2;
			my $lemma= $3;
			#For LV and LT this is irrelevant, but for EN the <unknown> lemma causes problems, therefore, we replace the lemma! 11.11.2011.
			if ($lemma eq "<unknown>")
			{
				$lemma = lc($token);
			}
			my $possibleMorfTag = $4;
			if ($possibleMorfTag ne "") { $possibleMorfTag =~s/\t//gi;} 
			#Adds a backslash to  special characters  to suppress their special meaning.
			$token =~ s/([\[\\\^\$\.\|\?\*\+\(\)\{\}])/\\$1/g; 

			$plain =~ /($token)/g; #Find the first match of the token in text.
			my $start = pos($plain) - length ($1); #Calculates the start and end positions of the token in text.
			my $end= pos($plain); 

			substr($plain, 0,$end) = ''; #Removes the token from text.
			$start += $postion ; #Finds the position in the actual plaintext file.
			$end +=$postion  ;
			$postion = $end; #Saves the position of the remaining line in text.
			$end=$end-1;
			$token =~ s/\\([\[\\\^\$\.\|\?\*\+\(\)\{\}])/$1/gi;  #Removes the extra backslashs added earlier.
			
			#Prints the token with its position.
			print OUT $token."\t".$tag."\t".$lemma."\t".$possibleMorfTag."\t".$line."\t".$start."\t".$line."\t".$end."\n";  
			if ($plain=~/^\s*$/){last;}
		}
	undef $plain;	
	$line +=1; 
	}  
	close PLAIN;
	close TOKENS;
	close OUT;
}

1;
