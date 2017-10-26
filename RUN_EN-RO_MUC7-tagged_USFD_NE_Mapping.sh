#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./EntityMappingWorkflow.pl"

perl ./EntityMappingWorkflow.pl --source EN --target RO --param "propFile=TEST/USFD-USFD.prop" --param method=NE --param parsedSource=1 --param parsedTarget=1 --param skipMapping=0 --input "./TEST/en_ro_muc7_pairs_in.txt" --output "./TEST/en_ro_muc7_USFD_NE_pairs_out.txt"

echo "EntityMappingWorkflow.pl finished."