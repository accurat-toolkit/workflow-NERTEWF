#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./EntityMappingWorkflow.pl"

perl ./EntityMappingWorkflow.pl --source DE --target EN --param "propFile=TEST/USFD-USFD.prop" --param method=PT --input "./TEST/en_de_phrtest_pexacc_in.txt" --output "./TEST/en_de_phrtest_pexacc_tabsep_out.txt"

echo "EntityMappingWorkflow.pl finished."