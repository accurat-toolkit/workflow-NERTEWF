#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./TermTagDirectory.pl"

perl ./TermTagDirectory.pl "./TEST/unlabeled_plaintext_in" "./TEST/annotated_plaintext_out" txt txt "./Sample_Data/lv_exec_plain.prop"

echo "TermTagDirectory.pl finished."
