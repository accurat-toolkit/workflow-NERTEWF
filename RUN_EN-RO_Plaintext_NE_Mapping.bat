cd %~dp0
@echo off
echo Calling "./EntityMappingWorkflow.pl"

perl EntityMappingWorkflow.pl --source EN --target RO --param "propFile=TEST/USFD-USFD.prop" --param method=NE --param parsedSource=0 --param parsedTarget=0 --param skipMapping=0 --input "./TEST/en_ro_plain_pairs_in.txt" --output "./TEST/en_ro_NE_pairs_out.txt"

echo EntityMappingWorkflow.pl finished.