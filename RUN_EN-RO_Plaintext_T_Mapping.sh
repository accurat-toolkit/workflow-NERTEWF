#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./EntityMappingWorkflow.pl"

perl ./EntityMappingWorkflow.pl --source EN --target RO --param "propFile=TEST/RACAI-USFD.prop" --param method=T --param parsedSource=0 --param parsedTarget=0 --param skipMapping=0 --input "./TEST/en_ro_plain_pairs_in.txt" --output "./TEST/en_ro_T_pairs_out.txt"

echo "EntityMappingWorkflow.pl finished."