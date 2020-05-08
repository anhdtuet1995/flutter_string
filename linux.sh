rm -rf output
mkdir output

in2csv -e utf-8 input.xlsx > input.csv

dart read.dart config.txt input.csv output/en.json

rm input.csv