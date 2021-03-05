echo generate index.html
pandoc --template ./template/GitHub.html5 -s index.md -o index.html
mkdir -p html-gen
for file in $(ls ./md-source)
do
    echo generate ${file%.*}.html
    pandoc --template ./template/GitHub.html5 --highlight-style my.theme --syntax-definition syn.xml -s ./md-source/$file -o ./html-gen/${file%.*}.html
done
