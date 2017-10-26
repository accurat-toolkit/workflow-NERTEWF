cd %~dp0
@echo off
echo Calling "./EntityMappingWorkflow.pl"

perl EntityMappingWorkflow.pl --source EN --target RO --param "propFile=TEST/USFD-USFD.prop" --param method=T --param parsedSource=1 --param parsedTarget=1 --param skipMapping=0 --input "./TEST/en_ro_term_pairs_in.txt" --output "./TEST/en_ro_term_USFD_T_pairs_out.txt"

echo EntityMappingWorkflow.pl finished.