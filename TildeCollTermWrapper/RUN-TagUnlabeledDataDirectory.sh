#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./TagUnlabeledDataDirectory.pl"

perl ./TagUnlabeledDataDirectory.pl lv Tagger "./TEST/unlabeled_plaintext_in" "./TEST/unlabeled_tabsep_out" txt pos 1

echo "TagUnlabeledDataDirectory.pl finished."
