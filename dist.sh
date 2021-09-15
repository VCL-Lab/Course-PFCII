./generate.sh
rm -rf dist
mkdir dist
mkdir dist/2021-spring
cp index.html dist/index.html
cp -r html-gen dist/html-gen
cp -r assets dist/assets
cp -r figures dist/figures

cp 2021-spring/index.html dist/2021-spring/index.html
cp -r 2021-spring/html-gen dist/2021-spring/html-gen
cp -r 2021-spring/assets dist/2021-spring/assets
cp -r 2021-spring/figures dist/2021-spring/figures