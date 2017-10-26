#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./EntityMappingWorkflow.pl"

perl ./EntityMappingWorkflow.pl --source EN --target LV --param "propFile=TEST/USFD-USFD.prop" --param method=T --param parsedSource=1 --param parsedTarget=1 --param skipMapping=0 --input "./TEST/en_lv_term_pairs_in.txt" --output "./TEST/en_lv_term_T_pairs_out.txt"

echo "EntityMappingWorkflow.pl finished."