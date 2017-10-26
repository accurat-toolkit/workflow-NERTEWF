cd %~dp0
@echo off
echo Calling "./PreprocessAnnotatedDataDirectory.pl"

perl ./PreprocessAnnotatedDataDirectory.pl "./TEST/gold_plaintext_in" "./TEST/gold_tabsep_out" txt gold lv Tagger

echo PreprocessAnnotatedDataDirectory.pl finished.