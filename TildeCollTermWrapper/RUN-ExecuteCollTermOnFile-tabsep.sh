#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./ExecuteCollTermOnFile.pl"

perl ./ExecuteCollTermOnFile.pl "./TEST/tabsep_in.pos" "./TEST/annotated_tabsep_out.pos" "./Sample_Data/lv_exec_tabsep.prop"

echo "ExecuteCollTermOnFile.pl finished."
