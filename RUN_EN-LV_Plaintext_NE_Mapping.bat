cd %~dp0
@echo off
echo Calling "./EntityMappingWorkflow.pl"

perl EntityMappingWorkflow.pl --source EN --target LV --param "propFile=TEST/USFD-USFD.prop" --param method=NE --param parsedSource=0 --param parsedTarget=0 --param skipMapping=0 --input "./TEST/en_lv_plain_pairs_in.txt" --output "./TEST/en_lv_NE_pairs_out.txt"

echo EntityMappingWorkflow.pl finished.