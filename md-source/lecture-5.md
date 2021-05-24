---
title: 前沿计算实践II
---

# Lecture 5: Make and CMake

## Make


当我们日常工作时，常常需要写一些与代码无关的事情。比如代码写完了，需要用命令行将其编译和连接，或者将一个代码的运行结果或输出放到另一个代码能找到的位置。这些繁琐的事情每一件都可以用脚本完成，但是如果要手动做这些事情会显得过于繁琐，此时我们一般使用Build System来完成这些事情。

Build System要完成的工作很简单，你告诉它你要生成什么文件(目标，Target)，生成的时候要使用哪些文件(依赖项，Dependencies)， 生成时使用的命令。此外，在你执行生成命令时，他会帮你检查依赖项是否有更新，如果没有就自动省略这次生成。




[An overview of build systems](https://julienjorge.medium.com/an-overview-of-build-systems-mostly-for-c-projects-ac9931494444)

[Meta Programming](https://missing.csail.mit.edu/2020/metaprogramming/)

[CMAKE tutorial](https://cmake.org/cmake/help/latest/guide/tutorial/index.html)

[How to CMake Good](https://www.youtube.com/watch?v=V1YP7eJHDJE)
