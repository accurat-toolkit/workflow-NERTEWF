cd %~dp0
@echo off
echo Calling "./EntityMappingWorkflow.pl"

perl EntityMappingWorkflow.pl --source DE --target EN --param "propFile=TEST/USFD-USFD.prop" --param method=PT --input "./TEST/en_de_phrtest_pexacc_in.txt" --output "./TEST/en_de_phrtest_pexacc_tabsep_out.txt"

echo EntityMappingWorkflow.pl finished.