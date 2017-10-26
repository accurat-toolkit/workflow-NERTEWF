#!/usr/bin/perl
#========File: EntityMappingWorkflow.pl=========
#Title:        EntityMappingWorkflow.pl - Entity Mapping Workflow for ACCURAT Tools.
#Description:  The entity mapping workflow executes named entity recognition or terminology extraction on monolingual data and maps bilingually the extracted named entities or terms (according to the specified input parameters).
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      12.08.2011.
#Last Changes: 05.06.2012. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Encode;
use encoding "UTF-8";
use Cwd;

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path to places whre Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

my $sourceLanguage;
my $targetLanguage;
my $propFile;
my $method;
my $sourceParsed = "0";
my $targetParsed = "0";
my $skipMapping = "0";
my $inputPath;
my $outputPath;

print STDERR "[EntityMappingWorkflow] Reading argument properties.\n";
#First of all, read the command line properties.
for (my $i=0; $i<$#ARGV; $i++)
{
	if ($ARGV[$i] eq "--source")
	{
		if (defined $ARGV[$i+1])
		{
			$sourceLanguage = $ARGV[$i+1];
		}
	}
	elsif ($ARGV[$i] eq "--target")
	{
		if (defined $ARGV[$i+1])
		{
			$targetLanguage = $ARGV[$i+1];
		}
	}
	elsif ($ARGV[$i] eq "--param")
	{
		my $propValue;
		if (defined $ARGV[$i+1])
		{
			$propValue = $ARGV[$i+1];
		}
		if (defined $propValue)
		{
			my ($key, $value) = split(/=/, $propValue, 2);
			if (defined $key && defined $value)
			{
				$key =~ s/^\s+//;
				$key =~ s/\s+$//;
				$value =~ s/^\s+//;
				$value =~ s/\s+$//;
				if (uc($key) eq "PROPFILE")
				{
					$propFile = NormalizePath($value);
				}
				if (uc($key) eq "SKIPMAPPING")
				{
					$skipMapping = $value;
				}
				elsif (uc($key) eq "METHOD")
				{
					$method = uc($value);
				}
				elsif (uc($key) eq "PARSEDSOURCE")
				{
					$sourceParsed = $value;
				}
				elsif (uc($key) eq "PARSEDTARGET")
				{
					$targetParsed = $value;
				}
			}
		}
	}
	elsif ($ARGV[$i] eq "--input")
	{
		if (defined $ARGV[$i+1])
		{
			$inputPath = NormalizePath($ARGV[$i+1]);
		}
	}
	elsif ($ARGV[$i] eq "--output")
	{
		if (defined $ARGV[$i+1])
		{
			$outputPath = NormalizePath($ARGV[$i+1]);
		}
	}
}

#If any properties are missing, print usage again and quit.

if (!(defined($sourceLanguage)
	&&defined($targetLanguage)
	&&(defined($method)&&($method eq "T" || $method eq "NE" || $method eq "PT"))
	&&defined($inputPath)
	&&defined($outputPath)))
{
	Usage();
	die;
}

if (!defined($propFile))
{
	$propFile = $Bin."/NE-TermWorkflowProperties.prop";
}

print STDERR "[EntityMappingWorkflow] Source Language: $sourceLanguage.\n";
print STDERR "[EntityMappingWorkflow] Target Language: $targetLanguage.\n";
print STDERR "[EntityMappingWorkflow] Property file: $propFile.\n";
print STDERR "[EntityMappingWorkflow] Method: $method.\n";
print STDERR "[EntityMappingWorkflow] Input Path: $inputPath.\n";
print STDERR "[EntityMappingWorkflow] Output Path: $outputPath.\n";

#Read the property file
print STDERR "[EntityMappingWorkflow] Reading external properties:\n";
my %propertyHash = ReadPropertyFile($propFile);
foreach my $key (keys %propertyHash)
{
	print STDERR "[EntityMappingWorkflow]   $key: ".$propertyHash{$key}."\n";
}

#Read the source and target languages and parse them to a 2 lowercase character code.
my $lcSource = GetTwoCharCode($sourceLanguage);
my $lcTarget = GetTwoCharCode($targetLanguage);

if ($method eq "PT")
{
	my $tempFile = $inputPath."_tabsep.txt";
	ConvertFromPexaccToTabsep($inputPath, $tempFile);
	my $workingPath = $Bin."/LT_P2GACC/";
	my $dataPath =  $Bin."/LT_P2GACC/data";
	my $phrT2GloPath = $Bin."/LT_P2GACC/OpenP2G-v05.jar";
	my $thr = $propertyHash{"PhrT2Glo_Thr"};
	my $execCommand = "cd \"".$workingPath."\" && java -Xms512m -Xmx1024m -jar \"".$phrT2GloPath."\" \"".$tempFile."\" \"".$outputPath."\" $lcSource $lcTarget \"".$dataPath."\" pexacc ".$thr;
	print STDERR "[EntityMappingWorkflow] Executing LT P2GACC: ".$execCommand."\n";
	my $res = `$execCommand`;
	unlink ($tempFile);
}
else
{
	#Regardless of task, prepare pairs for NE or term tagging.
	open(INFILE, "<:encoding(UTF-8)", $inputPath);
	my $sourceDocListFile = $inputPath.".".$method.".source.lst";
	open(OUTSOURCE, ">:encoding(UTF-8)", $sourceDocListFile);
	my $targetDocListFile = $inputPath.".".$method.".target.lst";
	open(OUTTARGET, ">:encoding(UTF-8)", $targetDocListFile);
	my $mapperListFile = $inputPath.".".$method.".mapper.lst";
	open(MAPPER, ">:encoding(UTF-8)", $mapperListFile);
	my %sourceFileHash;
	my %targetFileHash;
	while (<INFILE>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if ($line ne "" && $line !~ /#.*/)
		{
			my @arr = split(/\t/, $line);
			my $sourceFile = NormalizePath($arr[0]);
			my $targetFile = NormalizePath($arr[1]);
			my $prob = "0";
			if (defined $arr[2])
			{
				$prob = $arr[2];
			}
			$sourceFile =~ s/^\s+//;
			$sourceFile =~ s/\s+$//;
			$targetFile =~ s/^\s+//;
			$targetFile =~ s/\s+$//;
			#print "$sourceFile\t$targetFile\n";
			if (-e ($sourceFile) && -e ($targetFile))
			{
				my $newSource = $sourceFile.".".$method."_tagged";
				my $newTarget = $targetFile.".".$method."_tagged";
				if (!defined $sourceFileHash{$sourceFile})
				{
					print OUTSOURCE $sourceFile."\t".$newSource."\n";
					$sourceFileHash{$sourceFile} = $newSource;
				}
				if (!defined $targetFileHash{$targetFile})
				{
					print OUTTARGET $targetFile."\t".$newTarget."\n";
					$targetFileHash{$targetFile} = $newTarget;
				}
				if ($sourceParsed eq "1")
				{
					$newSource = $sourceFile;
				}
				if ($targetParsed eq "1")
				{
					$newTarget = $targetFile;
				}
				print MAPPER $newSource."\t".$newTarget."\t".$prob."\n";
			}
		}
	}

	undef %targetFileHash;
	undef %sourceFileHash;

	close INFILE;
	close OUTSOURCE;
	close OUTTARGET;
	close MAPPER;

	#Execute either NE or term extraction.
	if (uc($method) eq "NE")
	{
		if ($sourceParsed eq "0")
		{
			print STDERR "[EntityMappingWorkflow] Tagging named entities in the source documents.\n";
			TagNamedEntities($sourceDocListFile, $lcSource, $Bin, %propertyHash);
		}
		else
		{
			print STDERR "[EntityMappingWorkflow] Skipping named entity tagging in the source documents.\n";
		}
		
		if ($targetParsed eq "0")
		{
			print STDERR "[EntityMappingWorkflow] Tagging named entities in the target documents.\n";
			TagNamedEntities($targetDocListFile, $lcTarget, $Bin, %propertyHash);
		}
		else
		{
			print STDERR "[EntityMappingWorkflow] Skipping named entity tagging in the target documents.\n";
		}
		
	}
	elsif (uc($method) eq "T")
	{
		if ($sourceParsed eq "0")
		{
			print STDERR "[EntityMappingWorkflow] Tagging terms in the source documents.\n";
			TagTerms($sourceDocListFile, $lcSource, $Bin, %propertyHash);
		}
		else
		{
			print STDERR "[EntityMappingWorkflow] Skipping term tagging in the source documents.\n";
		}
		if ($targetParsed eq "0")
		{
			print STDERR "[EntityMappingWorkflow] Tagging terms in the target documents.\n";
			TagTerms($targetDocListFile, $lcTarget, $Bin, %propertyHash);
		}
		else
		{
			print STDERR "[EntityMappingWorkflow] Skipping term tagging in the target documents.\n";
		}
	}
	else
	{
		print STDERR "[EntityMappingWorkflow] Unsupported method: \"$method\". Use \"T\" or \"NE\"\n";
		die;
	}
	if ($skipMapping ne "1")
	{
		my $mapper = uc ($propertyHash{"MapperToUse"});
		if ($mapper eq "USFD")
		{
			my $mapperThr = uc ($propertyHash{"MapperUSFD_Thr"});
			my $workingPath = $Bin."/USFD_Tools/";
			my $mapperPath = $Bin."/USFD_Tools/MapperUSFD.jar";
			my $idx = "2";
			if (uc($method) eq "T")
			{
				$idx = "1";
				if ($propertyHash{"MapperUSFD_UseDictForTerms"} eq "1")
				{
					$idx .= "-Trans";
				}
			}
			my $execCommand = "cd \"".$workingPath."\" && java -jar \"".$mapperPath."\" ".uc($method)." \"".$mapperListFile."\" \"".$outputPath."\" ".uc($method).$idx." $lcSource $lcTarget $mapperThr";
			
			print STDERR "[EntityMappingWorkflow] Executing MapperUSFD: ".$execCommand."\n";
			my $res = `$execCommand`;
			print $res;
		}
		elsif ($mapper eq "RACAI")
		{
			if (uc($method) eq "T")
			{
				my $gizaFile = $Bin."/RACAI_TA/".$lcSource."_".$lcTarget;
				if (-e $gizaFile)
				{
					my $additionalMarkup = uc ($propertyHash{"RACAITermAligner_MoreAnnot"});
					my $workingPath = $Bin."/RACAI_TA/";
					my $mapperPath = $Bin."/RACAI_TA/TerminologyAligner.exe";
					my $execCommand = "cd \"".$workingPath."\" && \"".$mapperPath."\" --input \"".$mapperListFile."\" --output \"".$outputPath."\"  --source $lcSource --target $lcTarget --param \"aa=$additionalMarkup\"";
					print STDERR "[EntityMappingWorkflow] Executing RACAI TA: ".$execCommand."\n";
					my $res = `$execCommand`;
				}
				else
				{
					print STDERR "[EntityMappingWorkflow] Could not find a valid translation lexicon in address: $gizaFile.\n";
					die;
				}
			}
			else
			{
				my $gizaFile = $Bin."/RACAI_NERA2/".$lcSource."_".$lcTarget;
				if (-e $gizaFile)
				{
					my $additionalMarkup = uc ($propertyHash{"RACAINERA2_MoreAnnot"});
					my $workingPath = $Bin."/RACAI_NERA2/";
					my $mapperPath = $Bin."/RACAI_NERA2/NERA2.exe";
					my $execCommand = "cd \"".$workingPath."\" && \"".$mapperPath."\" --input \"".$mapperListFile."\" --output \"".$outputPath."\"  --source $lcSource --target $lcTarget --param \"aa=$additionalMarkup\"";
					print STDERR "[EntityMappingWorkflow] Executing RACAI NERA2: ".$execCommand."\n";
					my $res = `$execCommand`;
				}
				else
				{
					print STDERR "[EntityMappingWorkflow] Could not find a valid translation lexicon in address: $gizaFile.\n";
					die;
				}
			}
		}
		else
		{
			print STDERR "[EntityMappingWorkflow] Unsupported mapper (or language - mapper combination): \"$mapper\". Use \"USFD\" (any language pair) or \"RACAI\" (EN-RO pairs only).\n";
			die;
		}
	}
	else
	{
		print STDERR "[EntityMappingWorkflow] Skipping mapping as requested.\n";
	}

	unlink ($sourceDocListFile);
	unlink ($targetDocListFile);
	unlink ($mapperListFile);
}
exit;

sub Usage
{
	print "usage: perl EntityMappingWorkflow.pl [ARGS]\nARGS:\n\t1. --source [Source Language] - the 1st data file language.\n\t2. --target [Target Language] - the 2nd data file language.\n\t3. --param \"propFile=[Property File For Execution]\" - a complex property file that contains all separate NE/term extractor and NE/term linker properties including paths to model files and executables.\n\t4. --param method=[Method] - for Term mapping use \"method=T\"; for NE-mapping use \"method=NE\"; for term-extraction from a PEXACC file use \"method=PT\".\n\t5. --param parsedSource=[1 or 0] - for a MUC-7 annotated or term annotated plaintext use 1; otherwise use 0.\n\t6. --param parsedTarget=[1 or 0] - for a MUC-7 annotated or term annotated plaintext use 1; otherwise use 0.\n\t7. --input [Input document pair file] - ComMetric, RACAI EMACC or USFD classifier output file.\n\t8. --output [Mapped Data Output File] - the mapped data output file.\n";
}

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

sub TagTerms
{
	my($fileList, $language, $Bin, %propHash) = @_;
	my $execCommand = "";
	if ($language eq "lv")
	{
		my $CollTermWrapperPath = $Bin."/TildeCollTermWrapper/ExecuteCollTermOnFileList.pl";
		my $propPath = $Bin."/TildeCollTermWrapper/Sample_Data/lv_exec_plain.prop";
		my $workingPath = $Bin."/TildeCollTermWrapper/";
		$execCommand = "cd \"".$workingPath."\" && perl \"".$CollTermWrapperPath."\" \"".$fileList."\" \"".$propPath."\"";
	}
	elsif ($language eq "lt")
	{
		my $CollTermWrapperPath = $Bin."/TildeCollTermWrapper/ExecuteCollTermOnFileList.pl";
		my $propPath = $Bin."/TildeCollTermWrapper/Sample_Data/lt_exec_plain.prop";
		my $workingPath = $Bin."/TildeCollTermWrapper/";
		$execCommand = "cd \"".$workingPath."\" && perl \"".$CollTermWrapperPath."\" \"".$fileList."\" \"".$propPath."\"";
	}
	elsif ($language eq "en")
	{
		my $defaultTE = $propHash{"DefaultEnTE"};
		if ($defaultTE eq "USFD")
		{
			my $tePath = $Bin."/USFD_Tools/KEATEWrapper.jar";
			my $workingPath = $Bin."/USFD_Tools/";
			$execCommand = "cd \"".$workingPath."\" && java -jar \"".$tePath."\" \"".$fileList."\""; #
		}
		elsif ($defaultTE eq "RACAI")
		{
			my $tePath = $Bin."/RACAI_TE/TerminologyExtraction.exe";
			my $workingPath = $Bin."/RACAI_TE/";
			$execCommand = "cd \"".$workingPath."\" && \"".$tePath."\" --input \"".$fileList."\" --source en";
		}
		elsif ($defaultTE eq "TILDE_FFZG")
		{
			my $CollTermWrapperPath = $Bin."/TildeCollTermWrapper/ExecuteCollTermOnFileList.pl";
			my $propPath = $Bin."/TildeCollTermWrapper/Sample_Data/en_exec_plain.prop";
			my $workingPath = $Bin."/TildeCollTermWrapper/";
			$execCommand = "cd \"".$workingPath."\" && perl \"".$CollTermWrapperPath."\" \"".$fileList."\" \"".$propPath."\"";
		}
		else
		{
			print STDERR "[EntityMappingWorkflow::TagTerms] The default ENGLISH TE is not specified.\n";
			die;
		}
		
	}
	elsif ($language eq "ro")
	{
		my $tePath = $Bin."/RACAI_TE/TerminologyExtraction.exe";
		my $workingPath = $Bin."/RACAI_TE/";
		$execCommand = "cd \"".$workingPath."\" && \"".$tePath."\" --input \"".$fileList."\" --source ro";
	}
	else
	{
		print STDERR "[EntityMappingWorkflow::TagTerms] $language TE interface not found.\n";
		die;
	}
	print STDERR "[EntityMappingWorkflow::TagTerms] Executing TE: $execCommand\n";
	my $res = `$execCommand`;
	print $res;
}

sub TagNamedEntities
{
	my($fileList, $language, $Bin, %propHash) = @_;
	my $execCommand = "";
	if ($language eq "lv")
	{
		#The only Latvian NER is the TildeNER system, therefore, we assume TildeNER as the default system.
		my $nerPath = $Bin."/TildeNER/NEMuc7TagPlaintextList.pl";
		my $modelPath = $Bin."/TildeNER/Sample_Data/LV_Model_P.ser.gz";
		my $propPath = $Bin."/TildeNER/Sample_Data/LV_P_Tagging_prop_sample.prop";
		my $refDefStr = $propHash{"LV_RefDefString"};
		my $workingPath = $Bin."/TildeNER/";
		$execCommand = "cd \"".$workingPath."\" && perl \"".$nerPath."\" \"".$modelPath."\" \"".$fileList."\" \"".$propPath."\" LV Tagger \"".$refDefStr."\"";
	}
	elsif ($language eq "lt")
	{
		#The only Lithuanian NER is the TildeNER system, therefore, we assume TildeNER as the default system.
		my $nerPath = $Bin."/TildeNER/NEMuc7TagPlaintextList.pl";
		my $modelPath = $Bin."/TildeNER/Sample_Data/LT_BASELINE_Model.ser.gz";
		my $propPath = $Bin."/TildeNER/Sample_Data/LT_B_Tagging_prop_sample.prop";
		my $refDefStr = $propHash{"LT_RefDefString"};
		my $workingPath = $Bin."/TildeNER/";
		$execCommand = "cd \"".$workingPath."\" && perl \"".$nerPath."\" \"".$modelPath."\" \"".$fileList."\" \"".$propPath."\" LT Tagger \"".$refDefStr."\"";
	}
	elsif ($language eq "en")
	{
		my $defaultNER = $propHash{"DefaultEnNER"};
		if ($defaultNER eq "USFD")
		{
			my $nerPath = $Bin."/USFD_Tools/OpenNLPWrapper.jar";
			my $workingPath = $Bin."/USFD_Tools/";
			$execCommand = "cd \"".$workingPath."\" && java -jar \"".$nerPath."\" \"".$fileList."\"";
		}
		elsif ($defaultNER eq "RACAI")
		{
			my $nerPath = $Bin."/RACAI_NERA1/NERA1.exe";
			my $workingPath = $Bin."/RACAI_NERA1/";
			$execCommand = "cd \"".$workingPath."\" && \"".$nerPath."\" --input \"".$fileList."\" --source en";
		}
		else
		{
			print STDERR "[EntityMappingWorkflow::TagNamedEntities] The default ENGLISH NER is not specified.\n";
			die;
		}
	}
	elsif ($language eq "hr")
	{
		print STDERR "[EntityMappingWorkflow::TagNamedEntities] CROATIAN NER interface not found.\n";
		die;
	}
	elsif ($language eq "el")
	{
		print STDERR "[EntityMappingWorkflow::TagNamedEntities] GREEK NER interface not found.\n";
		die;
	}
	elsif ($language eq "ro")
	{
		my $nerPath = $Bin."/RACAI_NERA1/NERA1.exe";
		my $workingPath = $Bin."/RACAI_NERA1/";
		$execCommand = "cd \"".$workingPath."\" && \"".$nerPath."\" --input \"".$fileList."\" --source ro";
	}
	elsif ($language eq "sl")
	{
		print STDERR "[EntityMappingWorkflow::TagNamedEntities] SLOVENIAN NER interface not found.\n";
		die;
	}
	elsif ($language eq "de")
	{
		print STDERR "[EntityMappingWorkflow::TagNamedEntities] GERMAN NER interface not found.\n";
		die;
	}
	else
	{
		print STDERR "[EntityMappingWorkflow::TagNamedEntities] $language NER interface not found.\n";
		die;
	}
	print STDERR "[EntityMappingWorkflow::TagNamedEntities] Executing NER: $execCommand\n";
	my $res = `$execCommand`;
	print $res;
}

sub GetTwoCharCode
{
	my $lang = $_[0];
	$lang = uc ($lang);
	if ($lang eq "EN" || $lang =~ /EN-.*/ || $lang eq "3081" || $lang eq "10249" || $lang eq "4105" || $lang eq "9225" || $lang eq "16393" || $lang eq "6153" || $lang eq "8201" || $lang eq "17417" || $lang eq "5129" || $lang eq "13321" || $lang eq "18441" || $lang eq "7177" || $lang eq "11273" || $lang eq "2057" || $lang eq "1033" || $lang eq "12297" || $lang eq "ENGLISH" || $lang eq "ENG")
	{
		return "en";
	}
	elsif ($lang eq "RO" || $lang eq "1048" || $lang eq "ROMANIAN" || $lang eq "RON" || $lang eq "RUM")
	{
		return "ro";
	}
	elsif ($lang eq "SL" || $lang eq "1060" || $lang eq "SLOVENIAN" || $lang eq "SLV")
	{
		return "sl";
	}
	elsif ($lang eq "DE" || $lang =~ /DE-.*/ || $lang eq "1031" || $lang eq "GERMAN" || $lang eq "GER" || $lang eq "DEU")
	{
		return "de";
	}
	elsif ($lang eq "HR" || $lang eq "1050" || $lang eq "CROATIAN" || $lang eq "HRV")
	{
		return "hr";
	}
	elsif ($lang eq "EL" || $lang eq "1032" || $lang eq "GREEK" || $lang eq "GRE" || $lang eq "ELL")
	{
		return "el";
	}
	elsif ($lang eq "LV" || $lang eq "1062" || $lang eq "LATVIAN" || $lang eq "LAV")
	{
		return "lv";
	}
	elsif ($lang eq "LT" || $lang eq "1063" || $lang eq "LITHUANIAN" || $lang eq "LIT")
	{
		return "lt";
	}
	elsif ($lang eq "ET" || $lang eq "1061" || $lang eq "ESTONIAN" || $lang eq "EST")
	{
		return "et";
	}
	else
	{
		print STDERR "[EntityMappingWorkflow::GetTwoCharCode] Two character mapping for \"$lang\" not defined.\n";
		die;
	}
}

sub NormalizePath
{
	my $path = $_[0];
	#As a lot of the tools require executing from local tool directories, all input paths have to be normalized to absolute system paths!
	if (File::Spec->file_name_is_absolute($path))
	{
		return $path;
	}
	else
	{
		return File::Spec->rel2abs($path);
	}

}

sub ConvertFromPexaccToTabsep
{
	#Read input parameters - input file and output file paths.
	my $inputPath = $_[0];
	my $outputPath = $_[1];
	open(PEXACC, "<:encoding(UTF-8)", $inputPath);
	open(TABSEP, ">:encoding(UTF-8)", $outputPath);
	
	
	my $src = "";
	my $trg = "";
	my $prob = "";
	my $corrupt = 0;
	#Read each line of the PEXACC format document.
	while (<PEXACC>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if ($line eq "" || $line =~ /^\s*$/) #If the line is empty, check if a new non-corrupted data entry has been read.
		{
			if ($src !~ /^\s*$/ && $trg !~ /^\s*$/ && $prob =~ /^[-]?[0-9]+[.]{0,1}[0-9]*$/ && $corrupt == 0)
			{
				print TABSEP $src."\t".$trg."\t".$prob."\n"; #Print the new
			}
			$src = "";
			$trg = "";
			$prob = "";
			$corrupt = 0;
		}
		elsif ($src =~ /^\s*$/ || $src eq "") #If the first non-empty line is found:
		{
			$src = $line;
		}
		elsif ($trg =~ /^\s*$/ || $trg eq "") #If the second non-empty line is found:
		{
			$trg = $line;
		}
		elsif ($prob =~ /^\s*$/ || $prob eq "") #If the third non-empty line is found (assume it to be the probability):
		{
			$prob = $line;
		}
		else #If a fourth non-empty line is found (assume it to corrupt the data):
		{
			$corrupt = 1;
		}
	}
	close (PEXACC);
	close (TABSEP);
}