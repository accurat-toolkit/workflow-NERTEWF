#!/usr/bin/perl
#===========File: TEpostprocess.pm==============
#Title:        TEPostprocess.pm - Data Postprocessing Module for Tilde's CollTerm Wrapper System.
#Description:  The Module contains data post-processing methods for term extraction.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 01.08.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

package TEPostprocess;

use strict;
use warnings;

#======File: TagTermsFromMultipleFiles==========
#Title:        TagTermsFromMultipleFiles
#Description:  Tags terms from a term list file array (argument 1) in a POS tagged file (argument 0) using a term ranking method combining all lists using weights (argument 2) and prints them in file (argument 3). The term list files should be in equal number to the weights.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      Jan, 2012.
#Last Changes: 24.01.2012. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub TagTermsFromMultipleFilesV2
{
	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1])&&defined($_[2])&&defined($_[3]))
	{
		open(TOKENS, "<:encoding(UTF-8)", $_[0]);
		open(OUT, ">:encoding(UTF-8)", $_[3]);
	}
	else{die "Usage: TEPostprocess::TagTerms [Pos Taged File] [Term File Name Array] [Lambda Array] [Output File]\n";}

	#@termFiles - a list of files that contain term lists. Every single file must contain terms of the same length (token N-grams of a fixed size - N). The files must be in descending order according to term length.
	my @termFiles =  @{$_[1]};
	my @lambdas =  @{$_[2]};
	
	
	#%emptyLineHash - hash table that stores preceding empty lines of tokens in the POS-tagged document (required to print ampty lines in the output file).
	my %emptyLineHash;
	my %tokenHash;
	my $currentToken = 0;
	
	#@tokens - an array of tokens of the POS-tagged file.
	my @tokens;
	
	#Saves tokens from the POS-tagged file in an array and empty lines in the empty line hash table.
	while (my $tokenLine = <TOKENS>)
	{
		$tokenLine =~ s/\n//;
		$tokenLine =~ s/\r//;
		$tokenLine =~ s/^\x{FEFF}//; #Removes BOM.
		
		if ($tokenLine =~ /^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+).*$/)
		{
			my @token = ($1,$2,$3,$4,$5,$6,$7,$8,"O",0); # $1 - token, $2 - POS tag, $3 - lemma, $4 - Morphological tag, $5 - starting line, $6 - starting position, $7 - end line, $8 - end position, "O" - empty term tag, 0 - empty term tag probibility.
			push @tokens, [@token];
			if (!defined($tokenHash{$3}))
			{
				$tokenHash{$3} = ();
			}
			my $lcLemma = lc ($3);
			push @{$tokenHash{$lcLemma}}, $currentToken;
			$currentToken ++;
		}
		else
		{
			#Counts the amount of empty lines before the next non-empty line and fills the hash table with the amounts assigned to the non-empty line.
			if (defined $emptyLineHash{$currentToken})
			{
				$emptyLineHash{$currentToken}++ ;
			}
			else
			{
				$emptyLineHash{$currentToken} = 1;
			}
		}
	}
	my %termHash;
	#Reads each term file and creates an ordered list of terms.
	my $idx = -1;
	for my $TermFileIndex (0 .. $#termFiles)
	{
		$idx++;
		open(TERMS, "<:encoding(UTF-8)",$termFiles[$TermFileIndex]) or die "cant open $termFiles[$TermFileIndex]\n";
		#Saves terms and their probabilities in a hash.
		while  (my $term = <TERMS>)
		{
			$term =~ s/\n//;
			$term =~ s/\r//;
			$term =~ s/^\x{FEFF}//; #Removes BOM.
			if($term =~ /^([^\t]+)\t([^\t]+)$/)
			{
				#Splits term in to tokens.
				#my @splitTerm = split(" ",$1);
				
				my $realTerm = $1;
				#Gets term probobility.
				#print "L $idx: ".$lambdas[$idx]."\n";
				#print $2."\n";
				my $prob = $2*$lambdas[$idx];
				#print $prob."\n";
				$termHash{$realTerm} = $prob;
			}
		}
	}
	my $tokenCount = @tokens;
	my @sortedTerms = reverse sort { $termHash{$a} cmp $termHash{$b} } keys %termHash; 
	for my $i (0 .. $#sortedTerms)
	{
		#print $sortedTerms[$i]."\n";
		#print $termHash{$sortedTerms[$i]}."\n";
		#print $sortedTerms[$i]."\n";
		my @splitTerm = split(" ",$sortedTerms[$i]);
		my $candidateTerm = lc($splitTerm[0]);
		if (defined ($tokenHash{$candidateTerm}))
		{
			my @rootIdxArray = @{$tokenHash{$candidateTerm}};
			for my $r (0 .. $#rootIdxArray)
			{
				my $startIdx = $rootIdxArray[$r];
				my $goodToMark = 1;
				my $row = -1;
				SPTERM: for my $t (0 .. $#splitTerm)
				{
					my $lcTermLemma = lc($splitTerm[$t]);
					my $currIdx = $startIdx+$t;
					if ($currIdx>=$tokenCount)
					{
						$goodToMark=0;
						last SPTERM;
					}
					else
					{
						if ($row == -1)
						{
							$row = $tokens[$currIdx][4];
						}
						elsif ($tokens[$currIdx][4] != $row)
						{
							$goodToMark=0;
							last SPTERM;
						}
						my $lcTokenLemma = lc($tokens[$currIdx][2]);
						if($tokens[$currIdx][8] ne "O")
						{
							$goodToMark=0;
							last SPTERM;
						}
						elsif($lcTokenLemma ne $lcTermLemma)
						{
							$goodToMark=0;
							last SPTERM;
						}
					}
				}
				if ($goodToMark == 1)
				{
					for my $t (0 .. $#splitTerm)
					{
						my $currIdx = $startIdx+$t;
						if ($startIdx==$currIdx)
						{
							$tokens[$currIdx][8] = "B-TERM";
							$tokens[$currIdx][9] = $termHash{$sortedTerms[$i]};
						}
						else
						{
							$tokens[$currIdx][8] = "I-TERM";
							$tokens[$currIdx][9] = $termHash{$sortedTerms[$i]};
						}
					}
				}
			}
		}
	}
	#Save the POS-tagged tokens with newly added term tags in the output file.
	for my $z (0 .. $#tokens)
	{
		if (defined $emptyLineHash{$z})
		{
			for (1 .. $emptyLineHash{$z}) {print OUT "\n"; }
		}
		print OUT join ( "\t", @{$tokens[$z]} )."\n";
	}
	close OUT;
	close TOKENS;
}

#======File: TagTermsFromMultipleFiles==========
#Title:        TagTermsFromMultipleFiles
#Description:  Tags terms from a term list file array (argument 1) in a POS tagged file (argument 0) and prints them in file (argument 2). The term list files should be sorted in a descending order regarding the term length withing the term list files.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 01.08.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub TagTermsFromMultipleFiles
{
	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1])&&defined($_[2]))
	{
		open(TOKENS, "<:encoding(UTF-8)", $_[0]);
		open(OUT, ">:encoding(UTF-8)", $_[2]);
	}
	else{die "Usage: TEPostprocess::TagTerms [Pos Taged File] [Term File Name Array] [Output File]\n";}

	#@termFiles - a list of files that contain term lists. Every single file must contain terms of the same length (token N-grams of a fixed size - N). The files must be in descending order according to term length.
	my @termFiles =  @{$_[1]};
	
	#%emptyLineHash - hash table that stores preceding empty lines of tokens in the POS-tagged document (required to print ampty lines in the output file).
	my %emptyLineHash;
	my $currentToken = 0;
	
	#@tokens - an array of tokens of the POS-tagged file.
	my @tokens;
	
	#Saves tokens from the POS-tagged file in an array and empty lines in the empty line hash table.
	while (my $tokenLine = <TOKENS>)
	{
		$tokenLine =~ s/\n//;
		$tokenLine =~ s/\r//;
		$tokenLine =~ s/^\x{FEFF}//; #Removes BOM.
		
		if ($tokenLine =~ /^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+).*$/)
		{
			my @token = ($1,$2,$3,$4,$5,$6,$7,$8,"O",0); # $1 - token, $2 - POS tag, $3 - lemma, $4 - Morphological tag, $5 - starting line, $6 - starting position, $7 - end line, $8 - end position, "O" - empty term tag, 0 - empty term tag probibility.
			push @tokens, [@token];
			$currentToken ++;
		}
		else
		{
			#Counts the amount of empty lines before the next non-empty line and fills the hash table with the amounts assigned to the non-empty line.
			if (defined $emptyLineHash{$currentToken})
			{
				$emptyLineHash{$currentToken}++ ;
			}
			else
			{
				$emptyLineHash{$currentToken} = 1;
			}
		}
	}
	
	#Reads each term file and tags terms in tokens that have not already been tagged.
	for my $TermFileIndex (0 .. $#termFiles)
	{
		open(TERMS, "<:encoding(UTF-8)",$termFiles[$TermFileIndex]) or die "cant open $termFiles[$TermFileIndex]\n";
		
		#%termHash - a hash that holds terms as tokens in hash. The primary key of the hash is a list of tokens in terms. The primary key is linked to secondary key which is the term number identifying the term(s) the token is in. The secondary key is linked to an array which holds the position(s) the token is in the term.
		#Structure: %termHash{Term Token}{Term Number}[Array Of Token Position(s) In Term]
		my %termHash;
		
		#An array that holds term probabilities.
		my @termProb;
		
		#%operationalHash holds term numbers linked to starting positions of possible terms, relevant to current examined token.
		#Structure: %oprationalHash{Term Number}[Array Of Possible Starting Positions Of Term]
		my %oprationalHash;
		
		#termSize - token count in term.
		my $termSize;
		
		#A number that identifies each term.
		my $termNumber = 0;
		
		#Saves terms in a hash and their probabilities in an array.
		while  (my $term = <TERMS>)
		{
			$term =~ s/\n//;
			$term =~ s/\r//;
			$term =~ s/^\x{FEFF}//; #Removes BOM.
			if($term =~ /^([^\t]+)\t([^\t]+)$/)
			{
				#Splits term in to tokens.
				my @splitTerm = split(" ",$1);
				#Saves term probobility.
				push (@termProb,$2);
				#Saves the count of tokens in term. (Actually the diference between the end and starting positions, which is by one less than the token count ($#splitTerm))
				if ($termNumber == 0){$termSize = $#splitTerm;}		
				
				#Creates a hash value for each token in terms.
				for my $i (0 .. $#splitTerm)
				{
					if(defined $termHash{$splitTerm[$i]})
					{
						if(defined $termHash{$splitTerm[$i]}{$termNumber})
						{
							push (@{$termHash{$splitTerm[$i]}{$termNumber}}, $i);
						}
						else
						{
							my @tempArr = ($i);
							$termHash{$splitTerm[$i]}{$termNumber} = \@tempArr;
						}
					}
					else
					{
						my @tempArr = ($i);
						$termHash{$splitTerm[$i]}{$termNumber} = \@tempArr;
					}
				}
			}	
			$termNumber++;
		}

		#Iterates through POS tagged tokens looking for tokens that match the Term tokens and tags them if the whole term matches.
		for my $i (0 .. $#tokens)
		{
			#If the token has alredy been taged ignores it and clears %oprationalHash.
			if ($tokens[$i][8] eq "O")
			{
				#If the token isn't a part of any of the terms ignores it and clears %oprationalHash.
				if(defined ($termHash{$tokens[$i][2]}))
				{
					#%temphash - a temporary hash that stores operational hash values and replaces operational hash after adding current token term position values. This is done to separate newly added term tokens from the ones added from the last POS-tagged token.
					my %temphash; 
					#Iterates through all terms the token is in.
					TERMTOK: for my $termNumber (keys  %{$termHash{$tokens[$i][2]}})
					{
						#Iterates through all positions in the term, in which the token is in.
						for my $tokenPosInTerm (0 .. $#{$termHash{$tokens[$i][2]}{$termNumber}} )
						{
							#If the term has been added in operational hash and matched so far, check if it matches now and tag it if the full term has matched.
							if(defined($oprationalHash{$termNumber}))
							{
								#Iterate through start positions of a term. This is done to handle the cases when a term has two (or more) identical tokens.
								for my $termsStartPosIndex(0 .. $#{$oprationalHash{$termNumber}})
								{	
									#If the token position in term is equal to the amount of tokens that have matched so far, update the term in the operational hash.
									if ( ${$termHash{$tokens[$i][2]}{$termNumber}}[$tokenPosInTerm] = $i-$oprationalHash{$termNumber}[$termsStartPosIndex])
									{
										#If one of the terms is fully matched, add the tag to tokens and go to the next token.
										if ($i- $oprationalHash{$termNumber}[$termsStartPosIndex] == $termSize)
										{
											#Add "B-TERM" tag to the first token of the term and "I-TERM" tag to the proceding tokens. Add the term probability from @termProb array.
											for my $j (0 ..  $termSize)
											{
												if ($j==0) 
												{ 
													$tokens[${$oprationalHash{$termNumber}}[$termsStartPosIndex]][8] = "B-TERM"; 
													$tokens[$oprationalHash{$termNumber}[$termsStartPosIndex]][9] = $termProb[$termNumber]; 	
												}
												else 
												{
													$tokens[${$oprationalHash{$termNumber}}[$termsStartPosIndex] + $j][8]= "I-TERM"; 
													$tokens[${$oprationalHash{$termNumber}}[$termsStartPosIndex] + $j][9]= $termProb[ $termNumber]; 
												}
											}
											undef %temphash; # FAST BUGFIX - please check if correct!
											undef %oprationalHash;
											last TERMTOK;
											
										}
										#If the Term is not fully matched, save it in the oprationalHash.
										elsif ( defined($temphash{$termNumber}))
										{
											push (@{$temphash{$termNumber}}, ${$oprationalHash{$termNumber}}[$termsStartPosIndex]);
										}
										else
										{
											my @tempArr = (${$oprationalHash{$termNumber}}[$termsStartPosIndex]);
											$temphash{$termNumber} = \@tempArr;
										}
									}
								}
							}
							#If the matched token is in the beginning of a term, add it to oprationalHash.
							if (${$termHash{$tokens[$i][2]}{$termNumber}}[$tokenPosInTerm] == 0)
							{
								if ( defined($temphash{$termNumber}))
								{
									push (@{$temphash{$termNumber}},$i);
								}
								else
								{
									my @tempArr = ($i);
									$temphash{$termNumber} = \@tempArr;
								}
								#If the matched token is in the beginning and the term consists of a single token, tag the token and go to the next token.
								if($termSize == 0) 
								{
									$tokens[$i][8]= "B-TERM"; 
									$tokens[$i][9] = $termProb[$termNumber];
									undef %oprationalHash;
									undef %temphash; # FAST BUGFIX - please check if correct!
									last TERMTOK;
								}
							}
							
						}
					}
					undef %oprationalHash;
					%oprationalHash = %temphash;
				}
				else
				{
					undef %oprationalHash;
				}
			}
			else
			{
				undef %oprationalHash;
			}
		}
		close TERMS;
	}
	
	#Save the POS-tagged tokens with newly added term tags in the output file.
	for my $z (0 .. $#tokens)
	{
		if (defined $emptyLineHash{$z})
		{
			for (1 .. $emptyLineHash{$z}) {print OUT "\n"; }
		}
		print OUT join ( "\t", @{$tokens[$z]} )."\n";
	}
	close OUT;
	close TOKENS;
}


#===============File: TagTerms==================
#Title:        TagTerms
#Description:  Tags terms (argument 1) in a list of POS-tagged tokens (argument 0) and prints them in a file (argument 2). The method is NOT IN USE by the system.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 04.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub TagTerms
{
	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1])&&defined($_[2]))
	{
		open(TOKENS, "<:encoding(UTF-8)", $_[0]);
		open(TERMS, "<:encoding(UTF-8)", $_[1]);
		open(OUT, ">:encoding(UTF-8)", $_[2]);
	}
	else{die "Usage: TEPostprocess::TagTerms [Pos Taged File] [Term File] [Output File]\n";}
	
	my %emptyLineHash;
	my $currentToken = 0;
	
	my %terms;
	my @tokens;
	
	#Saves terms in a hash %terms;
	#Stucture: %terms{Full Term}[[An Array Of Each Token In Term][Term Probability]]
	while  (my $term = <TERMS>)
	{
		$term =~ s/\n//;
		$term =~ s/\r//;
		$term =~ s/^\x{FEFF}//; #Removes BOM.
		if($term =~ /^([^\t]+)\t([^\t]+)$/)
		{
			my @splitTerm =split(" ",$1);
			@{$terms{$1}} = (\@splitTerm,$2);
		}

	}
	
	#Saves the tokens in an array and the empty lines of the file in hash.
	while (my $tokenLine = <TOKENS>)
	{
		$tokenLine =~ s/\n//;
		$tokenLine =~ s/\r//;
		$tokenLine =~ s/^\x{FEFF}//; #Removes BOM.
		
		if ($tokenLine =~ /^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+).*$/)
		{
			my @token = ($1,$2,$3,$4,$5,$6,$7,$8,"O",0); # $1 - token, $2 - POS tag, $3 - lemma, $4 - Morphological tag, $5 - starting line, $6 - starting position, $7 - end line, $8 - end position, "O" - empty term tag, 0 - empty term tag probibility
			push @tokens, [@token]; 
			$currentToken ++;
		}
		else
		{
			#Saves empty lines in a hash and counts the amount of successing the empty lines.
			if (defined $emptyLineHash{$currentToken})
			{
				$emptyLineHash{$currentToken}++ ;
			}
			else
			{
				$emptyLineHash{$currentToken} = 1;
			}
		}
	}
	
	# Tags terms one by one. Tags the longest terms first.
	for my $key (sort {length($b)<=>length($a)} (keys %terms))
	{
		#Iterates through untagged tokens and compares the POS tagged token with the first token in term and it matches tries to match the entire term.
		for my $i (0 .. $#tokens)
		{
			
			if ($tokens[$i][8] eq "O")
			{
				if ($tokens[$i][0] eq ${$terms{$key}}[0][0])
				{
					my $matches = 1;
					for my $termTokens (1 .. $#{$terms{$key}[0]})
					{
						if ($#tokens < $i+$termTokens) {$matches = 0; last;}
						if ($tokens[$i+$termTokens][8] ne "O") {$matches = 0; last;}
						if ($tokens[$i+$termTokens][0] ne ${$terms{$key}}[0][$termTokens])
						{
							$matches = 0;
							last;
						}
					}
					
					if ($matches)
					{
						$tokens[$i][8] = "B-TERM";
						$tokens[$i][9] = $terms{$key}[1];
						for my $termTokens (1 .. $#{$terms{$key}[0]})
						{
							$tokens[$i+$termTokens][8] = "I-TERM";
							$tokens[$i+$termTokens][9] = $terms{$key}[1];
						}
					}
				}
				
			}
		}
	}
	
	#Save the POS tagged tokens with newly added term tags in the output file.
	for my $i (0 .. $#tokens)
	{
		if (defined $emptyLineHash{$i})
		{
			for (1 .. $emptyLineHash{$i}) {print OUT "\n"; }
		}
		print OUT join ( "\t", @{$tokens[$i]} )."\n";
	}
	
	close OUT;
	close TOKENS;
	close TERMS;
	
}

#=====File: TaggedTokensToTaggedPlaintext=======
#Title:        TaggedTokensToTaggedPlaintext
#Description:  Applies term markup to a plaintext document (argument 1) from a POS-tagged document (argument 0). The results are saved in a term-tagged plaintext document (argument 2).
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      July, 2011.
#Last Changes: 01.08.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub TaggedTokensToTaggedPlaintext
{

	#Checking if all required parameters are set.
	if(defined($_[0])&&defined($_[1])&&defined($_[2]))
	{
		open(TOKENS, "<:encoding(UTF-8)", $_[0]);
		open(PLAIN, "<:encoding(UTF-8)", $_[1]);
		open(OUT, ">:encoding(UTF-8)", $_[2]);
	}
	else{die "Usage: TEPostprocess::TagTerms [Taged Token File] [Output File]\n";}
	#@termPos - an array of term tag positions.
	#Structure: @termPos[Term Number][Positions] 
	# Positions: [0] - start line, [1] - start position in the line, [2] - end line, [3] - end position in the line.

	my @termPos;
	
	my @singleTermPos;
	my $inNETag = 0;
	#Gets term positions from the POS-tagged file.
	while (my $tokenLine = <TOKENS>)
	{
		$tokenLine=~s/\n//;
		$tokenLine=~s/\r//;
		$tokenLine =~ s/^\x{FEFF}//; #Removes BOM.
		if ($tokenLine =~ /^[^\t]+\t[^\t]*\t[^\t]*\t[^\t]*\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/g)
		{
			# $1 - starting line, $2 - starting position, $3 - end line, $4 - end position, 5 -  term tag,
			my $termTag = $5;
			my @tokenPositions = ($1,$2,$3,$4);
			
			#If there has been a term tag that has not been closed so far.
			if ($inNETag)
			{
				#If the term has ended, save it in the @termPos array.
 				if ($termTag !~ /^I/)
				{
					if($singleTermPos[0]==$singleTermPos[2] ) {  push @termPos,[@singleTermPos]; }
					$inNETag = 0;
					undef @singleTermPos;
				}
				
				#If the token is the first token in term, save its positions and set the indicator to the status "Within a term".
				if ($termTag =~ /^B/) 
				{ 
					@singleTermPos = ($tokenPositions[0],$tokenPositions[1],$tokenPositions[2],$tokenPositions[3]);
					$inNETag = 1;
				}
				
				#If the current token is a part of a previously opened term, save its end positions in @singleTermPos.
				elsif ($termTag =~ /^I/)
				{
					$singleTermPos[2] = $tokenPositions[2];
					$singleTermPos[3] = $tokenPositions[3];
				}
				next;
			}
			
			#If the token is the first token in a term, save its positions and specify that there has been a beginning of a term.
			if ($termTag =~ /^B/) 
			{ 
				@singleTermPos = ($tokenPositions[0],$tokenPositions[1],$tokenPositions[2],$tokenPositions[3]);
				$inNETag = 1;
			}
		}
	}
	
	#Saves the last term, if the beginning was found but the term was not saved.
	if ($inNETag)
	{	
		push @termPos,[@singleTermPos];
		$inNETag = 0;
		undef @singleTermPos;
	}
	
	#Count plaintext line numbers, to match term positions used in POS tagged token files.
	my $linenum = 0;
	
	#Add starting and ending term tags to a plaintext line using starting and ending positions in @termPos array.
	while (my $plainLine = <PLAIN>)
	{
		#Saves the length of added tags to get term positions after adding a tag.
		my $addedTagLenght =0;
		
		#Looks for line matches in the @termPos array and adds the tag if a match is found.
		for my $i (0 .. $#termPos)
		{
			$plainLine =~ s/^\x{FEFF}//; #Removes BOM.
			if ($termPos[$i][0]==$linenum)
			{
					$plainLine = substr($plainLine,0,$termPos[$i][1]+$addedTagLenght).'<TENAME>'. substr($plainLine,$termPos[$i][1]+$addedTagLenght);
					$addedTagLenght = $addedTagLenght + 8;
			}
			if ($termPos[$i][2]==$linenum)
			{
					$plainLine = substr($plainLine,0,$termPos[$i][3]+$addedTagLenght+1).'</TENAME>'. substr($plainLine,$termPos[$i][3]+$addedTagLenght+1);
					$addedTagLenght = $addedTagLenght + 9;
			}
		}
		#Prints the tagged line to the output file.
		print OUT $plainLine;
		$linenum++;
	}
	close OUT;
	close TOKENS;
	close PLAIN;
}

1;