---
title: 前沿计算实践II
---

# Lecture 1: Linux Basic & Shell Script

本课程参考[MIT](https://web.mit.edu/)课程[The Missing Semester of Your CS Education](https://missing.csail.mit.edu/)，考虑到同学们之前上过课程的基础以及科研需要进行适当调整。

## Linux Overview

[Linux](https://en.wikipedia.org/wiki/Linux)是一群**开源**的、基于**Linux内核**的**类Unix操作系统**集合。

* 操作系统(operating system)：管理计算机硬件和软件资源的程序，为用户程序提供硬件抽象和接口。
* 操作系统内核(operating system kernel)：操作系统最核心的部分，管理系统的进程、内存、设备驱动程序、文件和网络系统，一直在内存中，不包括图形界面、Shell等功能
* Shell：内核的封装，为用户提供更高级的抽象，比如`echo`、`ls`、`cd`等命令，以及进程间通信功能（管道）
* Unix内核：最早形成规模，被广泛使用的操作系统，由肯•汤普森(Ken Thompson)和丹尼斯•里奇(Dennis Ritchie)发明，使用C编写，现在常用的基于UNIX内核的操作系统有[Solaris](https://www.oracle.com/solaris/solaris11/)、[FreeBSD](https://www.freebsd.org/)
* Linux内核：由李纳斯•托瓦兹(Linus Torvalds)在赫尔辛基大学读书时出于个人爱好而编写的，当时他觉得教学用的迷你版UNIX操作系统Minix太难用了，于是决定自己开发一个操作系统。第1版本于1991年9月发布，当时仅有10000行代码。李纳斯•托瓦兹没有保留Linux源代码的版权，公开了代码，并邀请他人一起完善Linux。据估计，现在只有2%的Linux核心代码是由李纳斯•托瓦兹自己编写的，虽然他仍然拥有Linux内核（操作系统的核心部分），并且保留了选择新代码和需要合并的新方法的最终裁定权(Benevolent dictator for life, BDFL)。

> [Windows](https://www.microsoft.com/en-us/windows)使用的是NT内核(New Technology Kernenl)，同样借鉴了UNIX内核，正如名称所言图形界面窗口是Windows中很重要的一部分，与之相对的Linux系统很大一部分优势在于其命令行操作的遍历性及良好的生态，而不依赖于图形界面。[macOS](https://www.apple.com/macos/big-sur/)内核被官方称为XNU。这个首字母缩写词代表“XNU is Not Unix”。根据苹果公司的Github页面，XNU是“将卡耐基梅隆大学开发的Mach内核和FreeBSD组件整合而成的混合内核，加上用于编写驱动程序的 C++ API”。macOS也有很方便的命令行界面且

在Linux内核的基础上衍生出了大量的操作系统，满足不同情况下的各种需求，每一个称为一个发行版(distribution,distro)。

![Linux distro timeline](..\figures\linuxdistrotimeline.png)

常用的Linux发行版有[Red Hat](https://www.redhat.com)、[Ubuntu](https://ubuntu.com/)、[SuSE](www.suse.com)、[Gentoo](www.gentoo.org)、[CenterOS](www.centos.org)、[Arch Linux](https://archlinux.org/)等等，本课程将主要介绍Ubuntu系统，因其简单易用，其他发行版可以直接简单对应，因为他们基于的都是相同的内核。

## Ubuntu

Ubuntu的安装方法与Windows类似，可以在官网上下载ISO映像文件然后使用工具制作U盘启动盘比如[UltraISO](https://www.ultraiso.com/)，然后重启进入BIOS界面从U盘启动安装系统。Ubuntu可以与Windows作为双系统共存，网上有很多教程。如果不想安装双系统也可以选择虚拟机，Windows下也可以考虑下面介绍的WSL。

如果使用的是没有图形界面版的Ubuntu，那么开机之后进入的就是Shell的控制台。在图形界面下，可以通过终端(Terminal)进入Shell控制台，Ubuntu默认的终端是[gnome terminal](https://help.gnome.org/users/gnome-terminal/stable/)，也可以自行安装[Terminator](https://linuxx.info/terminator/)或者其他终端模拟器，区别只在于图形界面和窗口管理。比如gnome terminal每个窗口只能打开一个命令行，想要切换只能手动寻找窗口然后点开，这对于很多视动鼠标为耻辱的程序员来说是不能接受的，因此可以选择Terminator在一个窗口下打开多个命令行。但另一方面也可以使用[Tmux](https://github.com/tmux/tmux)在任何终端上实现这一功能。

Ubuntu默认的Shell是Bourne Again Shell(bash)，打开终端出现的紫框就是bash的界面：  
![](..\figures\bash-purple.png)

[zsh](http://zsh.sourceforge.net/)是bash的升级版，在bash基础功能之上实现了拼写检查、路径补全、插件、主题等功能，相比bash对用户更为友好。在zsh的基础上还能再使用[oh-my-zsh](https://ohmyz.sh/)进一步使用各种便利功能和主题，美化终端：  
![](..\figures\oh-my-zsh.png)

> 在Windows下也可以使用Windows Terminal、Power Shell、Oh-My-Posh达到同样的美观效果

## 常用命令

|命令|功能|命令|功能|
|:---:|:---:|:---:|:---:|
|date|显示时间|rm|删除|
|shutdown -h now|关闭系统|mv|移动、重命名|
|man|查看帮助文档|cp|复制|
|cat|显示文件内容|touch|新建文件|
|cd|切换当前路径|ln|链接|
|pwd|显示当前路径|find|寻找文件|
|ls|查看目录中的文件|whereis|寻找命令路径|
|mkdir|新建目录|passwd|修改密码|




## 权限

在Linux中所有东西都可以视为文件，应用、目录、锁等等，每个文件都有对应权限，当我们使用`ls -l`命令时就能查看目录下所有文件的权限：
```bash
dd@ubuntu~:$ ls -l /
total 684
lrwxrwxrwx   1 root root      7 Aug  5  2020 bin -> usr/bin
drwxr-xr-x   2 root root   4096 Aug  5  2020 boot
...
-rwxr-xr-x   3 root root 631968 Sep 15 17:30 init
...
```
首先是文件的所有者，对应第三栏和第四栏，第三栏的`root`表示文件的所有者是root，也就是超级用户(superuser)，第四栏表示文件的所有组，Linux会默认为每个用户单独创建一个组，用户也可以自己创建。Linux针对每个文件为文件的所有者、所在组以及其他用户分配了不同的权限，在第一栏显示。第一栏一共10个字符，第一个字符是文件的种类，第二到第四个字符表示文件的所有者权限，第五到第七个字符表示文件所有组的权限，第八到第十个字符表示其他人的权限。首先是文件种类，这里`d`表示文件是一个目录，`-`表示是单纯的文件，`l`表示文件是一个软连接，这是一个文件系统的概念，可以认为软连接是一个类似指针的东西，只存储了目标在文件系统中的位置，与之相对的还有硬链接，之间的区别可以看[这篇文章](https://www.jianshu.com/p/dde6a01c4094)。后面每三个字符表示一组权限，`r`表示可读，`w`表示可写，`x`表示可执行。于是我们就明白了`bin`是一个指向`usr/bin`的软链接，所有人可读、可写、可执行，但`boot`目录直有root用户可读、可写、可执行，其他用户只能读和执行。  
为了保护操作系统的稳定性和用户的安全，Linux限制了很多任务只能由root来执行，比如安装软件，删除某些重要文件，因此当用户尝试想要进行这些操作时，必须使用root账户。Linux提供了一个非常方便的命令`sudo`，也就是substitute user, and do，来使用户借用root账户来进行一些操作。比如当我们尝试用`apt-get`安装软件(下面会介绍)
```bash
dd@ubuntu:~$ apt-get install python
E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
```
系统会报错提示我们权限不够，这个时候只需要在前面加上`sudo`就没有问题了
```bash
dd@ubuntu:~$ sudo apt-get install python
```
系统会提示你输入密码然后执行安装命令。如果你有大量的命令需要在root权限下执行，也可以通过`su`命令进入root模式，就不需要在每个命令前加上`sudo`。  
另外一个重要的命令是改变文件权限的命令`chmod`，也就是change mode。比如我们新建了一个Shell脚本
```bash
dd@ubuntu:~$ touch hello.sh && echo "echo hello world" > hello.sh
dd@ubuntu:~$ ls -l
-rw-r--r-- 1 dd dd 17 Mar  3 13:54 hello.sh
```
可以看到此时脚本是可读可写但是不可执行的，直接执行就会报错
```bash
dd@ubuntu:~$ ./hello.sh
-bash: ./hello.sh: Permission denied
```
这时就需要通过`chmod`命令来为文件增加可执行的权限。`chmod`命令可以通过两种方法设定权限，一是通过数字直接指定权限，比如
```bash
chmod 744 hello.sh
```
这里的三个数字7、4、4分别表示所有者、所有组、其他人的权限，其中`x`对应1，`w`对应2，`r`对应4，那么`rwx`也就是4+2+1=7，换言之，744也就是表示所有者可读可写可执行，但是其他人只能读。或者我们也可以通过字符的方式，比如
```bash
chmod u+x hello.sh 
```
这里`u`表示user即所有者，类似的`g`表示group即所有组，`o`表示other即其他用户，`a`表示all即所有用户。中间的连接符可以是`+`、`-`、`=`表示增加、删除、指定某些权限，后面的`x`表示的就是执行权限，换言之`u+x`也就是为所有者增加执行权限。  
权限修改之后就可以直接执行了。值得注意的是，如果待修改权限的文件所有者并不是自己，就需要在`chmod`前加上`sudo`，此外，还可以通过`chown`来修改文件所有者，这里就不再赘述。

## 包管理

如果在Windows下安装某个应用程序，往往需要先下载安装器，一班后缀为`.exe`或者`.msi`，然后运行安装程序安装。在Ubuntu下，我们也可以在网站上下载软件包，后缀为`.deb`，然后调用`dpkg`进行安装：
```bash
sudo dpkg -i xxx.deb
```
`.deb`文件后缀是[Debian](https://www.debian.org/)系统的软件包格式，Ubuntu基于Debian开发因此使用相同的软件包格式，里面包含了程序的二进制文件、配置文件、man/info帮助页面等信息。用户不同的任务依赖大量的软件支撑，不同的软件往往有着复杂的依赖关系，一个软件往往也有很多版本，为了管理这么多的软件，Ubuntu提供了统一的软件管理机制，也就是`dpkg`和`apt`。
`dpkg`的用法如上所示，`dpkg -l`可以列出所有的以安装软件，`dpkg -r`卸载软件，更多命令可以使用`dpkg --help`或者`man dpkg`。dpkg安装完成之后，默认文件存放位置如下：

* 二进制文件：`/usr/bin`
* 库文件：`/usr/lib`
* 配置文件：`/etc`
* 使用手册和帮助文档：`/usr/share/doc`
* man帮助页面：`/usr/share/man`

然而dpkg并不是万能的，当某个软件的依赖项没有安装时dpkg就会报错，需要用户手动安装依赖项。apt很好地解决了这一问题。首先开发者会将编译后的二进制文件和软件信息存放在Ubuntu的源服务器上，当需要安装软件时，apt会自动从服务器上获取软件依赖信息，然后从服务器上下载依赖并安装，然后再安装需要的软件。服务器的信息记录在本地的`/etc/apt/sources.list`中：
```bash
dd@ubuntu~:$ cat /etc/apt/sources.list

deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse

deb http://archive.canonical.com/ubuntu focal partner
deb-src http://archive.canonical.com/ubuntu focal partner
```
在国内访问这些服务器可能速度比较慢，可以考虑更换为[清华源](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/)，在更换之前可以先备份默认配置以免后面找不到：
```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list_backup
```
改完之后更新apt就可以使用新的源了
```bash
sudo apt-get update 
```
使用apt-get安装软件非常简单：
```bash
sudo apt-get install xxx
```
apt会自动处理依赖并调用dpkg来安装这些包。apt和apt-get在使用上基本没有区别，具体差别可以查看[这篇文章](https://phoenixnap.com/kb/apt-vs-apt-get)。

## 重定向和管道

每个程序都是一个单独的进程，在Shell中执行命令实际上是fork出一个新的进程然后再执行命令，不同的进程之间虚拟内存地址不同，因而需要特别的机制来实现不同程序之间的通信，管道(pipeline)就是Linux的一个进程间的通信方式。  
在了解管道之前我们先看Linux是怎么完成输入和输出的重定向的。Linux下可以通过输出重定位符`>`和输入重定位符`<`重定位程序的输入和输出，比如
```bash
echo 'hello world' > hello.txt
```
就可以将`echo`的输出重定位到`hello.txt`中，如果想在文件末尾添加而不是覆盖，可以使用`>>`
```bash
echo 'hello world' >> hello.txt
```
这样就可以不覆盖文件原来的内容。类似的我们可以
```bash
cat < hello.txt
```
将`hello.txt`作为`cat`的输入。  
有了重定向的机制后，假如我们想将命令A的输出作为命令B的输入，就可以先将A的输出保存到一个文件中，然后再将文件作为B的输入，但这样做无疑是麻烦而且低效的，而如果使用管道机制，我们就可以直接一行命令`A | B`将A的输出作为B的输入，同时B可以在A还没有结束时就启动，并行运行提高效率。比如我们可以先`ls`目录信息然后查找其中的文件夹
```bash
dd@ubuntu~:$ ls -l / | grep 'home'
drwxr-xr-x   3 root root   4096 Dec  4 20:58 home
```
就可以立马看到对应`home`文件夹的那一行。利用管道我们可以组合不同的命令来方便地实现复杂的功能，这也是Linux命令行功能强大的重要原因。


## 环境变量

环境变量是一组操作系统能访问到的变量，在Shell中输入`env`就能查看当前所有的环境变量
```bash
dd@ubuntu~:$ env
/bin/bash
USER=dd
...
PATH=/home/dd/.local/bin:/home/dd/.local/bin:/usr/local/sbin:
/usr/local/bin:/usr/sbin:/usr/bin:...
...
```
环境变量可以保存默认设置、搜索路径等，比如我们可以看到系统的默认Shell是`bin/bash`，用户名是`dd`。我们可以在Shell和程序中使用这些变量，比如
```bash
dd@ubuntu~:$ echo $SHELL
/bin/bash
```
使用方法就是在环境变量名之间加上`$`，或者用大括号括起来之后再加`$`。一些软件在编译运行时需要依赖其他软件，这时如果可以在环境变量中找到已经安装的软件路径，就可以很方便地通过环境变量找到依赖，比如CMake中的`find_package`命令就会在环境变量中寻找匹配的包。  
环境变量中非常重要的一个是`PATH`，它指定了Shell寻找可执行文件的路径。可以看到`PATH`中包含了`usr/bin`，所以所有我们通过`apt-get`安装的软件都可以直接在Shell中使用。如果我们已经安装了某个软件但是在Shell中依然无法使用时，大概率是没有将安装的位置加入到`PATH`中。  
除了环境变量之外，还有Shell的变量，在命令行中输入`set | less`就能查看当前所有的Shell变量，只能在当前的Shell窗口下访问到，比如当我们定义
```bash
dd@ubuntu~:$ HELLO=hello
```
就可以在`set`中看到
```bash
dd@ubuntu~:$ set | grep "HELLO"
HELLO=hello
```
但是在环境变量中看不到
```bash
dd@ubuntu~:$ env | grep "HELLO"
```
并且如果我们进入一个子进程比如再打开一个bash
```bash
dd@ubuntu~:$ bash
dd@ubuntu~:$ set | grep "HELLO"
```
这时也看不到我们刚定义的变量了，输入`exit`退出子进程可以再次看到定义的变量
```bash
dd@ubuntu~:$ exit
dd@ubuntu~:$ set | grep "HELLO"
HELLO=hello
```
那么要怎么在Shell中定义和修改环境变量呢？可以使用`export`命令
```bash
export HELLO=hello
```
这时就可以在环境变量里找到定义的变量
```bash
dd@ubuntu~:$ env | grep "HELLO"
HELLO=hello
```
但是这时如果我们退回父进程或者重开一个控制台窗口，我们又不能看到定义的变量了。这是因为Shell中定义的环境变量之后影响子进程，为了避免我们每次都需要在使用前定义环境变量，我们可以将这一设置写进`~/.bashrc`里，这个配置文件会在每次启动bash时执行。`~/.bashrc`中已经包含了很多配置，我们要做的就是在最后添加
```bash
export HELLO=hello
```
然后执行`source ~/.bashrc`，这样就可以在每次打开Shell的时候定义这一环境变量。利用这个机制，假如我们想把自定义的命令加入`PATH`中时就可以在`~/.bashrc`中添加
```bash
export PATH=/path/to/bin:$PATH
```
这样命令就会添加到Shell的搜索路径中。需要注意的一点是，如果使用的是zsh，需要修改的就不是`~/.bashrc`，而是`~/.zshrc`。

## WSL

### 使用情景
[WSL](https://docs.microsoft.com/en-us/windows/wsl/)的全称是Windows Subsystem for Linux，即Windows的Linux子系统。

一般我们如果想要运行linux代码，需要安装双系统或者虚拟机，而WSL可以让我们直接在Windows下使用Linux的命令行和工具。

举一个例子，比如你在Windows下实现了一个新方法，需要将其和其他人的方法进行比对。然而你发现其他人的代码是在Linux下实现的(或者使用了bash脚本)，此时如果使用双系统或者虚拟机会面临以下的问题：

- 两份代码的比较过程中需要**反复切换操作系统**，操作复杂
- 两份代码的输出结果保存在**不同的文件系统中**，不一定能互访
- 难以将两份代码的结果用同样的方法进行后续处理。

而WSL(特指WSL1)则提供了一个在Windows下直接运行Linux代码的方法，其表现为，同一个文件夹下，你既可以用Windows的cmd进行操作，也可以用Linux的bash进行操作。

具体来讲，当你在Windows下用cmd打开一个文件夹，其界面会是这样：

```bash
Windows PowerShell
版权所有 (C) Microsoft Corporation。保留所有权利。

尝试新的跨平台 PowerShell https://aka.ms/pscore6

PS D:\Advance>
```


而此时在cmd里键入`bash`，则会切换成Linux的**bash**界面。

```bash
PS D:\Advance>bash
yhy@xxx:/mnt/d/Advance$
```

注意到，原本的`D:\Advance`文件夹此时被显示成`/mnt/d/Advance`文件夹，但是这只是由于文件系统不同造成的显示出来的路径不同，他们所指向的实际位置是一个。所以此时你在`bash`内输入的所有Linux指令都会真的作用于这个本属于Windows的文件夹。

> WSL2相对于WSL1，其更像一个真正的虚拟机，拥有完整的Linux内核。但是其在使用Windows文件系统时会更慢。

大多数情况下，我们都是希望在Linux上运行一个`server`，在Windows下对其进行访问。此时可以通过`localhost`直接访问。比如在bash内运行如下命令

```bash
# for python2
yhy@xxx:/mnt/d/Advance$ python -m SimpleHTTPServer 8001

# for python3
yhy@xxx:/mnt/d/Advance$ python3 -m http.server 8001
```

运行后，8001端口会提供一个对当前文件夹的服务。我们可以直接在浏览器内打开`http://localhost:8001/`，其会显示如下界面

![](..\figures\wsl-directories.png)


这会是`/mnt/d/Advance`文件夹里的内容。

但是如果反过来，我们想要在WSL内访问Windows的端口则不一定能直接访问，可能会需要获取主机IP(尝试了目前版本可以直接访问，和以前的说法不同)。

### 更好地使用WSL


#### 使用VS code
虽然我们在命令行里就可以使用Linux命令，但是在日常码代码时，我们还是希望能有更直观的操作，这时我们可以配套使用`VS code`。

在**Windows内**安装好VS code。安装`Remote Development`插件包(在extension内搜索即得)。之后在WSL的文件系统内，你可以通过输入下面的代码直接打开当前文件夹(例子为/home文件夹)

```bash
yhy@xxx:/home$ code .
```

#### 使用Windows Terminal

Windows Terminal让我们用多标签管理多个终端，并且支持更多的主题和背景。

![](..\figures\windows-terminal.png)

其设置可以在[Windows Terminal官方文档](https://docs.microsoft.com/en-us/windows/terminal/)中找到。


#### 直接在cmd内运行Linux命令

除了在cmd内键入bash，然后再执行Linux命令以外，可以直接在cmd内运行并保持cmd不变，比如执行`ls -la`代码只需要在前面加上`wsl`，即 

```bash
PS D:\Advance>wsl ls -la
```

由于cmd同样有管道和重定向机制，我们就可以把Windows和Linux特有的命令混合起来，比如Linux特有的`ls`输入给Windows特有的`findstr`

```bash
PS D:\Advance>wsl ls -la | findstr "figure"
```

或者反过来

```bash
PS D:\Advance>dir | wsl grep git
```

注意这里的管道是`cmd`的管道，不是和wsl结合的，也就是说

```bash
PS D:\Advance> wsl ls -la | grep git
# grep : 无法将“grep”项识别为 cmdlet、函数、脚本文件或可运行程序的名称。

PS D:\Advance> wsl ls -la | wsl grep git
# 正确结果
```

#### 在WSL里运行cmd命令

可以通过在bash内使用`[tool-name].exe`来调用Windows工具，比如

```bash
yhy@xxx:/home$ explorer.exe .
```

会在Windows的文件资源管理器内打开`/home`文件夹。

特别地，`cmd.exe`可以让我们在bash内直接使用cmd命令(就像我们在cmd内使用bash命令一样)

```bash
cmd.exe /C dir
```

## Shell Script

### 如何运行脚本

脚本语言本身只是区别于那些传统的，需要通过编译、链接才能运行的编程语言，其需要解释器来运行。

比如我们熟知的`python`就是一种脚本语言。在编写python的时候，我们可以交互式地逐行输入，也可以将程序写到一个文件里(如`helloworld.py`)，然后再在终端里输入`python3 helloworld.py`运行。

```python
print("hello world") 
# helloworld.py 的内容
```

```bash
$ python3 helloworld.py 
hello world #这是上面命令的输出
```

在上面的过程中，`helloworld.py`文件就是一个**脚本**，而`python3`则是我们给它指定的**解释器**。

同样的，我们也可以把`bash`的语句写到`xxx.sh`文件里，然后用`bash xxx.sh`运行脚本。此时，会运行一个新的`bash`解释器，并执行脚本`xxx.sh`。

```bash
echo 'hello world' 
# test.sh 的内容
```

```bash
$ bash test.sh
hello world #这是上面命令的输出
```

当然这只是一种运行脚本的方法，即将文件名当作参数传给要运行的解释器。

实际上，我们可以直接在文件里指定解释器，比如下面的`test.py文件`和`test.sh文件`

```python
#!/usr/bin/python3
print("hello world")
```

```bash
#! /usr/bin/bash
echo 'hello world' 
```

```bash
$ ./test.py
hello world
$ ./test.sh
hello world
```

其中`#!`称为`shebang`，是`sharp bang`的缩写，前者表示井号，后者是感叹号。其后跟着的路径会让内核能够找到该脚本的解释器，`shebang`需要写在首行。

有些时候，我们不知道解释器在哪个位置，只知道能通过环境变量`PATH`找到，此时可以把绝对路径改成下面的形式

```python
#! /usr/bin/env python3
print("hello world")
```

`/usr/bin/env`会帮助你运行环境变量中的解释器。

### 简单的bash语法

> 为了方便展示，短一点的语句我们可能在终端内交互式输入，长一些的则会写入文件运行，前者会在命令前加`$`表示这是输入的命令，其余部分为输出。后者会在代码块最上方加上shebang

#### 定义变量和简单输出

同python一样，bash shell作为编程语言同样有定义变量，控制流，函数等。但有些不同的是，空格在bash shell的语法里起着比较重要的作用，比如在定义变量时

```bash
$ a="hello world"
$ echo $a
hello world
```

定义了一个字符串变量`a`，想要获取它的值需要使用`$a`，`echo`负责把传给它的值输出到终端上。

而如果我们在等号周围加上了空格`a = "hello world"`，其就不再是一个赋值操作，而是试图调用程序`a`，并且传入参数`=`和`"hello world"`。

除此之外，赋值语句`a="hello world"`的形式是`var=value`，如果`value`本身不含有空格，可以把外面的引号删掉，比如

```bash
$ a=hello
$ echo $a
hello
```

这时hello虽然没加引号，但是依然被视为了字符串变量。bash shell的字符串同样面临转义的问题，一般来讲，单引号`''`包含的字符串是纯文本，不需要也不会进行转义，而双引号`""`中则是可以引用变量和转义的，比如

```bash
$ name=yhy
$ echo "your name is $name"
your name is yhy
$ echo 'your name is $name'
your name is $name
```

#### 函数，特殊变量，返回值和输出值

bash shell 同样可以定义函数，比如下面定义的`mcd`函数是`mkdir`和`cd`的结合，其会建立一个文件夹并切换进去。

```bash
mcd () {
    mkdir -p "$1"
    cd "$1"
}
```

这里`$1`是自动定义的特殊变量，它是函数收到的第一个参数。比如当我们调用`mcd testmcd`时，`$1`就是`testmcd`。

```bash
/mnt/d/Advance$ mcd testmcd
/mnt/d/Advance/testmcd$
```

这样的特殊变量还有很多，下面是一些常用的

|特殊变量|含义|
|:---:|:---:|
|`$0`|当前脚本的名字|
|`$1`到`$9`| 传入脚本的第x个参数|
|`$@`|所有参数|
|`$#`|参数的数目|
|`$$`|当前脚本的PID|
|`$?`|上一条指令的==返回值==|

注意到最后一条，我们特意标记了返回值，这是因为我们之前的操作(比如赋值，管道，echo)都是针对指令的==输出==，而返回值则是另外一件事情。

这里的返回值一般代表函数的运行状态，一般来讲`0`代表正常结束，其余值代表异常退出。这也是我们之前的操作不针对返回值的原因：它代表的信息很少。下面是一个关于返回值和输出的实验：

```bash
#! /usr/bin/bash
foo(){
echo "I'm output"
return 33
}

a=$(foo)

echo $?
echo $a
```

这里我们定义了一个`foo`函数，其输出`I'm output`，返回`33`。赋值语句`a=$(foo)`中，`()`的作用是表示其内的东西不是变量，而是需要运行的语句。这个脚本的输出如下
```shell = bash
33  
I'm output 
```

其中`33`是上一条语句的返回值，由于上一条语句是`a=$(foo)`为赋值语句，返回值为右侧的返回值，故而为`33`。

但是返回值也不是完全无法利用，比如就逻辑运算符会使用命令的返回值而不是输出值，如果命令正常结束，则获得布尔值`true`，否则是`false`（也就是说返回`0`为`true`，`1`为`false`）。比如bash有一条命令就叫做`true`，其什么也不做，只返回`0`，相对地，有一条命令叫`false`，其返回`1`。我们就可以进行如下验证：

```bash
$ true
$ echo $? #验证返回值
0

$ false
$ echo $? # 验证返回值
1

$ false || echo "Oops, fail"
Oops, fail
$ true || echo "Will not be printed"
```

在最后的操作里，`true || xxxx`没有执行后面的操作，这是因为其和`c++`一样，`||`在确认第一个值为`true`以后就不会执行后面的语句了，这可以用来在脚本里判断程序是否出错，同理

```bash
$ true && echo "Things went well"
Things went well
$ false && echo "Will not be printed"
```

#### 输出，临时文件，通配符

在ICS中我们学习过`文件描述符`的概念，系统预留的文件描述符如下：

|文件描述符|含义|
|:---:|:---:|
|`0`|`stdin` `标准输入`|
|`1`|`stdout` `标准输出`|
|`2`|`stderr` `标准错误`|

我们不进行重定向，直接运行命令时，终端会同时显示`标准输出`和`标准错误`信息。而我们之前的重定向`>`重定向的是`标准输出`，如果我们想要重定向`标准错误`需要用`2>`。

```bash
$ ls +
ls: cannot access '+': No such file or directory
$ ls + >out.txt 2>err.txt
# out.txt为空，err.txt内为输出
```

如果我们不想在终端上看到`stderr`的消息，可以把它重定向到`/dev/null`。

另外一个有趣的事情是关于输入的。上面我们看到`echo $(foo)`语法会执行一次`foo`，然后用其输出替换掉`$(foo)`。一个相似的语法是`<(foo)`，这会执行一次`foo`，将其输出放到一个临时文件，然后用`临时文件的名字`代替`<(foo)`。比如`diff`命令用于比较两个`文件`的不同

```bash
$ diff <(ls figure) <(ls testmcd)
```

就会比较出`figure`文件夹和`testmcd`文件夹的不同文件名。

#### 循环，条件，通配符，正则表达式

我们可以直接给一个例子来展示`bash`的循环与判断。我们目的是找到`code`文件夹下的所有`.py`文件和`.cpp`文件。

```bash
#! /bin/bash

for file in $(ls code/{*.cpp,*.py})
do	
	echo $file
done
```
其中`for`循环的形式不难理解，但是我们要注意这里是如何找到以`.cpp`和`.py`结尾的文件名的。

这一般称之为`Wildcard`(`通配符`)，其机制是如果想要用多个文件名做参数，那么可以给出这些文件名的统一的形式。bash会自动用能看到的所有文件名匹配这个模式，如果能匹配上，则放到命令里，然后执行。

一个简单的例子是通配符里用`*`匹配任意字符串，那么`*.txt`就会表示所有以`.txt`结尾的文件名。

```bash
$ echo *.txt
err.txt out.txt test.txt
```

这表示当前文件夹下有这些txt文件。如果可能有多种形式，可以用`{}`包围起来，形式之间用逗号隔开，比如`*.{cpp,py}`表示所有以`cpp`和`py`结尾的文件名。

要强调的是，通配符只是用来避免重复输入多个文件名的，其和正则表达式长得可能有些相似，但是并不一样。比如上面的`echo *.txt`实际的执行是bash先把这个命令替换成`echo err.txt out.txt test.txt`，然后执行这个新的命令。而正则表达式针对更广泛的字符串，并且bash本身是不支持替换正则表达式的。

当然使用正则表达式也能完成我们的这个任务，不过此时匹配工作不能交给bash来进行，我们需要寻找一些支持正则表达式的程序帮助执行，比如`grep`和`egrep`。下面是正则表达式版本的实现方式

```bash
for file in $(ls code)
do	
	egrep ".*\.(cpp|py)+" <(echo $file)
done
```

我们在此不详细讲正则表达式，只需要理解`egrep`接受了两个参数，一个是描述`所需形式`的正则表达式，一个是存有`文件名字`的临时文件(参见上面对`<()`的解释)。

### 有用的工具

linux的常用命令很多，各个选项也十分复杂，我们不大可能全部记住，一般来讲我们可以用`-h`或者`--help`选项获得帮助，但是我们还有其他更好的选择。

一个选择是用`man`指令，它会生成一个十分`详细`的帮助页。比如`man ls`会显示`ls`的所有功能和选项。

另外一个十分推荐的选择是`tldr`，它会给出`简略的描述和例子`，能让你更快地找到所需要的功能。

![](..\figures\tldr.png)


## Reference

* [Linux和UNIX的关系及区别](http://c.biancheng.net/view/707.html)
* [APT Vs APT-GET: What's The Difference?](https://phoenixnap.com/kb/apt-vs-apt-get)
* [5分钟让你明白“软链接”和“硬链接”的区别](https://www.jianshu.com/p/dde6a01c4094)
* [How to Set and List Environment Variables in Linux](https://www.digitalocean.com/community/tutorials/how-to-read-and-set-environmental-and-shell-variables-on-linux#setting-shell-and-environmental-variables)
* [WSL 官方文档](https://docs.microsoft.com/en-us/windows/wsl/)
* [同学推荐的 WSL 教程](https://dowww.spencerwoo.com/)