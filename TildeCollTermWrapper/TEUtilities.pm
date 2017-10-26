#!/usr/bin/perl
#=============File: TEUtilities.pm==============
#Title:        TEUtilities.pm - Utility Functions for Term Extraction.
#Description:  The Module contains utility functions used in term extraction.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      July, 2011.
#Last Changes: 26.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

package TEUtilities;

use File::Basename;
use File::Copy;
use strict;
use warnings;
use Switch;

#=========Method: ReadPropertyFile==========
#Title:        ReadPropertyFile
#Description:  Reads a property file (argument 0) and returns a hash of property keys and values.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      26.07.2011.
#Last Changes: 26.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub ReadPropertyFile
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: ReadPropertyFile [Input file]\n"; 
		die;
	}
	open(INFILE, "<:encoding(UTF-8)", $_[0]);
	my %propHash;
	while (<INFILE>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if ($line ne "" && $line !~ /#.*/)
		{
			my ($key, $value) = split(/=/, $line, 2);
			$key =~ s/^\s+//;
			$key =~ s/\s+$//;
			$value =~ s/^\s+//;
			$value =~ s/\s+$//;
			if (defined ($key) && defined ($value))
			{
				$propHash{$key} = $value;
			}
		}
	}
	close INFILE;
	return %propHash;
}

#=========Method: ApplyTermThreshold==========
#Title:        ApplyTermThreshold
#Description:  Reads a term list file (argument 0) and applies a threshold (argument 2) to the extracted terms. A new term list file (argument 1) is produced as a result.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      26.07.2011.
#Last Changes: 26.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub ApplyTermThreshold
{
	if (not(defined ($_[0])&&defined ($_[1])&&defined ($_[2]))) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: ApplyTermThreshold [Input file] [Output file] [Threshold]\n"; 
		die;
	}
	open(INFILE, "<:encoding(UTF-8)", $_[0]);
	open(OUTFILE, ">:encoding(UTF-8)", $_[1]);
	my $threshold = $_[2];
	my %propHash;
	while (<INFILE>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if ($line ne "")
		{
			my ($key, $value) = split(/\t/, $line, 2);
			$key =~ s/^\s+//;
			$key =~ s/\s+$//;
			$value =~ s/^\s+//;
			$value =~ s/\s+$//;
			if ($value>=$threshold)
			{
				print OUTFILE $line."\n";
			}
		}
	}
	close INFILE;
	close OUTFILE;
}

1;
