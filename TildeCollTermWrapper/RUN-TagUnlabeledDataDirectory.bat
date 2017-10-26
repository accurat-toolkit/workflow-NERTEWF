cd %~dp0
@echo off
echo Calling "./TagUnlabeledDataDirectory.pl"

perl ./TagUnlabeledDataDirectory.pl lv Tagger "./TEST/unlabeled_plaintext_in" "./TEST/unlabeled_tabsep_out" txt pos 1

echo TagUnlabeledDataDirectory.pl finished.