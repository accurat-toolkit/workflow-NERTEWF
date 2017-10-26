#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./PreprocessAnnotatedDataDirectory.pl"

perl ./PreprocessAnnotatedDataDirectory.pl "./TEST/gold_plaintext_in" "./TEST/gold_tabsep_out" txt gold lv Tagger

echo "PreprocessAnnotatedDataDirectory.pl finished."