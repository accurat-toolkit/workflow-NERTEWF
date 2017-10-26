#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./TermTagDirectory.pl"

perl ./TermTagDirectory.pl "./TEST/gold_tabsep_in" "./TEST/gold_annotated_tabsep_out" gold pos "./Sample_Data/lv_exec_tabsep.prop" "./TEST/eval.txt"

echo "TermTagDirectory.pl finished."
