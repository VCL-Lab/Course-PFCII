echo generate index.html
# pandoc -s index.md -o index.html --template ./template/GitHub.html5 --toc --toc-depth 2
# pandoc -s index.md -o index.html --template ./template/bootstrap.html --css ./template/bootstrap.css  --toc --toc-depth 2
pandoc -s index.md -o index.html --template ./template/uikit.html  --toc --toc-depth 2
mkdir -p html-gen
cd md-source
for file in $(ls)
do
    echo generate ${file%.*}.html
    # pandoc -s ./md-source/$file -o ./html-gen/${file%.*}.html --template ./template/GitHub.html5 --highlight-style my.theme --syntax-definition syn.xml --toc --toc-depth 2
    # pandoc -s $file -o ../html-gen/${file%.*}.html --template ../template/bootstrap.html --css ../template/bootstrap.css --toc --toc-depth 2 \
    # --highlight-style ../my.theme --syntax-definition ../syn.xml
    pandoc -s $file -o ../html-gen/${file%.*}.html --template ../template/uikit.html --toc --toc-depth 2 \
    --highlight-style ../my.theme --syntax-definition ../syn.xml
    # Hack! 让标题可以指向index.html
    sed -e "s/前沿计算实践II<\/h1>/<a href=\'..\/index.html\'>前沿计算实践II<\/a><\/h1>/g" ../html-gen/${file%.*}.html -i
done
