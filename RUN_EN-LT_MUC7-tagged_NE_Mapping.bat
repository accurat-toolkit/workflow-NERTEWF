cd %~dp0
@echo off
echo Calling "./EntityMappingWorkflow.pl"

perl EntityMappingWorkflow.pl --source EN --target LT --param "propFile=TEST/USFD-USFD.prop" --param method=NE --param parsedSource=1 --param parsedTarget=1 --param skipMapping=0 --input "./TEST/en_lt_muc7_pairs_in.txt" --output "./TEST/en_lt_muc7_NE_pairs_out.txt"

echo EntityMappingWorkflow.pl finished.