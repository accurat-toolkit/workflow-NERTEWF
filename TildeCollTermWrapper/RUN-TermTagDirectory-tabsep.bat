cd %~dp0
@echo off
echo Calling "./TermTagDirectory.pl"

perl ./TermTagDirectory.pl "./TEST/unlabeled_tabsep_in" "./TEST/annotated_tabsep_out" pos pos "./Sample_Data/lv_exec_tabsep.prop"

echo TermTagDirectory.pl finished.
