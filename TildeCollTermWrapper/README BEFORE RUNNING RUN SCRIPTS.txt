The RUN scripts are created for the user to test, whether the Tilde's Wrapper system for CollTerm operates on the user's system. The scripts are preconfigured for specific tasks on Latvian data and do not require any input parameters.

The scripts make use of input data that is stored in the "TEST" directory (a suffix "in" is used on directories and files located directly in the TEST directory) and stopword, phrase and property files that are stored in the "Sample_Data" directory.
Output data is stored also in the "TEST" directory (a suffix "out" is used on directories and files located directly in the TEST directory).

BAT scripts are meant to be executed on Windows
SH scripts are meant to be executed on Linux

The user won't be able to execute "bat" scripts on Linux and "sh" scripts on Windows.

The provided test scripts execute the "External Execution Scripts" from Tilde's Wrapper system for CollTerm (See section 4.1.4.2 in the ACCURAT project's Deliverable D2.6).

The scripts are as follows:

1) For PreprocessAnnotatedDataDirectory.pl (See section 4.1.4.2.1 in ACCURAT Deliverable D2.6):
	RUN-PreprocessAnnotatedDataDirectory.bat
	RUN-PreprocessAnnotatedDataDirectory.sh
2) For TagUnlabeledDataDirectory.pl (See section 4.1.4.2.2 in ACCURAT Deliverable D2.6):
	RUN-TagUnlabeledDataDirectory.bat
	RUN-TagUnlabeledDataDirectory.sh
3) For ExecuteCollTermOnFile.pl (See section 4.1.4.2.3 in ACCURAT Deliverable D2.6):
	3.1) For plaintext input and output:
		RUN-ExecuteCollTermOnFile-plaintext.bat
		RUN-ExecuteCollTermOnFile-plaintext.sh
	3.2) For tab-separated input and output:
		RUN-ExecuteCollTermOnFile-tabsep.bat
		RUN-ExecuteCollTermOnFile-tabsep.sh
4) For TermTagDirectory.pl (See section 4.1.4.2.4 in ACCURAT Deliverable D2.6):
	4.1) For plaintext input and output:
		RUN-TermTagDirectory-plaintext.bat
		RUN-TermTagDirectory-plaintext.sh
	4.2) For tab-separated input and output:
		RUN-TermTagDirectory-tabsep.bat
		RUN-TermTagDirectory-tabsep.sh
	4.3) For tab-separated gold annotated input and tab-separated output:
		RUN-TermTagDirectory-tabsep+gold.bat
		RUN-TermTagDirectory-tabsep+gold.sh
5) For ExecuteCollTermOnFileList.pl (See section 4.1.4.2.5 in ACCURAT Deliverable D2.6):
	5.1) For plaintext input and output:
		RUN-ExecuteCollTermOnFileList-plaintext.bat
		RUN-ExecuteCollTermOnFileList-plaintext.sh
	5.2) For tab-separated input and output:
		RUN-ExecuteCollTermOnFileList-tabsep.bat
		RUN-ExecuteCollTermOnFileList-tabsep.sh
