#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./EntityMappingWorkflow.pl"

perl ./EntityMappingWorkflow.pl --source EN --target LT --param "propFile=TEST/USFD-USFD.prop" --param method=T --param parsedSource=0 --param parsedTarget=0 --param skipMapping=0 --input "./TEST/en_lt_plain_pairs_in.txt" --output "./TEST/en_lt_T_pairs_out.txt"

echo "EntityMappingWorkflow.pl finished."