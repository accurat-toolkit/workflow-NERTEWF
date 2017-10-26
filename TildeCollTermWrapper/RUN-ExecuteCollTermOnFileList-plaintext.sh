#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./ExecuteCollTermOnFileList.pl"

perl ./ExecuteCollTermOnFileList.pl "./TEST/plaintext_fileList.txt" "./Sample_Data/lv_exec_plain.prop"

echo "ExecuteCollTermOnFileList.pl finished."
