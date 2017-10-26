cd %~dp0
@echo off
echo Calling "./ExecuteCollTermOnFileList.pl"

perl ./ExecuteCollTermOnFileList.pl "./TEST/tabsep_fileList.txt" "./Sample_Data/lv_exec_tabsep.prop"

echo ExecuteCollTermOnFileList.pl finished.

