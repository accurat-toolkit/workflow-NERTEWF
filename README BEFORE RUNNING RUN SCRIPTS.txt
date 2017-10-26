The RUN scripts are created for the user to test, whether the Named Entity Recognition and Term Extraction WorkFlow (NERTEWF) operates on the user's system. The scripts are preconfigured for specific tasks on English, Latvian, Lithuanian and Romanian data and do not require any input parameters.

The scripts make use of input data (also property files) that is stored in the "TEST" directory (a suffix "in" is used on directories and files located directly in the TEST directory).
Output data is stored also in the "TEST" directory (a suffix "out" is used on files located directly in the TEST directory; some files will be generated also in the input data directories, for instance, for NER the suffix "NE_tagged" (or "T_tagged" for TE) will be added to the file name).

BAT scripts are meant to be executed on Windows
SH scripts are meant to be executed on Linux

The user won't be able to execute "bat" scripts on Linux and "sh" scripts on Windows.

The provided test scripts execute the "EntityMappingWorkflow.pl" perl script of NERTEWF (See section 1.2.4 in the ACCURAT project's Deliverable D2.6).

The scripts are as follows:
1) Plaintext NE-tagging and mapping:
	1.1) For EN-LT:
		RUN_EN-LT_Plaintext_NE_Mapping.bat
		RUN_EN-LT_Plaintext_NE_Mapping.sh
	1.2) For EN-LV:
		RUN_EN-LV_Plaintext_NE_Mapping.bat
		RUN_EN-LV_Plaintext_NE_Mapping.sh
	1.3) For EN-RO (mapping with MapperUSFD):
		RUN_EN-RO_Plaintext_NE_Mapping.bat
		RUN_EN-RO_Plaintext_NE_Mapping.sh
2) Plaintext term-tagging and mapping:
	1.1) For EN-LT:
		RUN_EN-LT_Plaintext_T_Mapping.bat
		RUN_EN-LT_Plaintext_T_Mapping.sh
	2.2) For EN-LV:
		RUN_EN-LV_Plaintext_T_Mapping.bat
		RUN_EN-LV_Plaintext_T_Mapping.sh
	2.3) For EN-RO (mapping with MapperUSFD):
		RUN_EN-RO_Plaintext_T_Mapping.bat
		RUN_EN-RO_Plaintext_T_Mapping.sh
3) MUC-7 annotated document NE mapping (in this scenario NE-tagging is skipped):
	3.1) For EN-LT:
		RUN_EN-LT_MUC7-tagged_NE_Mapping.bat
		RUN_EN-LT_MUC7-tagged_NE_Mapping.sh
	3.2) For EN-LV:
		RUN_EN-LV_MUC7-tagged_NE_Mapping.bat
		RUN_EN-LV_MUC7-tagged_NE_Mapping.sh
	3.3) For EN-RO:
		3.3.1) Mapping with the RACAI NERA2 NE mapping tool:
			RUN_EN-RO_MUC7-tagged_RACAI_NE_Mapping.bat
			RUN_EN-RO_MUC7-tagged_RACAI_NE_Mapping.sh
		3.3.2) Mapping with the USFD MapperUSFD:
			RUN_EN-RO_MUC7-tagged_USFD_NE_Mapping.bat
			RUN_EN-RO_MUC7-tagged_USFD_NE_Mapping.sh
4) Term-annotated document term mapping (in this scenario term-tagging is skipped):
	4.1) For EN-LT:
		RUN_EN-LT_term-tagged_T_Mapping.bat
		RUN_EN-LT_term-tagged_T_Mapping.sh
	4.2) For EN-LV:
		RUN_EN-LV_term-tagged_T_Mapping.bat
		RUN_EN-LV_term-tagged_T_Mapping.sh
	4.3) For EN-RO:
		4.3.1) Mapping with the RACAI TA term mapping tool:
			RUN_EN-RO_term-tagged_RACAI_T_Mapping.bat
			RUN_EN-RO_term-tagged_RACAI_T_Mapping.sh
		4.3.2) Mapping with the USFD MapperUSFD:
			RUN_EN-RO_term-tagged_USFD_T_Mapping.bat
			RUN_EN-RO_term-tagged_USFD_T_Mapping.sh
5) Term mapping from parallel sentences/phrases:
	5.1) For EN-DE:
		RUN_EN-DE_PEXACC_RES_T_Mapping.bat
		RUN_EN-DE_PEXACC_RES_T_Mapping.sh
