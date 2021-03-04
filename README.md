To generate html pages, using
```
pandoc --template ./tempalte/GitHub.html5 -s ./md-source/lecture-1.md -o ./html-gen/lecture-1.html
```

images in Markdown should be included as
```
![](..\figures\xxx.png)
```