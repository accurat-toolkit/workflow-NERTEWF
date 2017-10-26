#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./ExecuteCollTermOnFile.pl"

perl ./ExecuteCollTermOnFile.pl "./TEST/plaintext_in.txt" "./TEST/annotated_plaintext_out.txt" "./Sample_Data/lv_exec_plain.prop"

echo "ExecuteCollTermOnFile.pl finished."
