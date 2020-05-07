::Remove all old outputs
rd /s /q output
mkdir output

::Office must be installed in your Windows
::Convert xlxs to txt for reading file easier
cscript convert.vbs input.xlsx input.txt

dart read.dart config.txt input.txt output/en.json

::Delete temporary input file
del /f input.txt
