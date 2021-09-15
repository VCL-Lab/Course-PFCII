---
title: 前沿计算实践II
---

# Lecture 3: Git & Misc

本课程参考[MIT](https://web.mit.edu/)课程[The Missing Semester of Your CS Education](https://missing.csail.mit.edu/)，考虑到同学们之前上过课程的基础以及科研需要进行适当调整。

## Git

[Git](https://git-scm.com/)是由Linus Torvalds为了帮助管理Linux内核开发而开发的一个开放源码的版本控制软件。所谓版本控制，就是将不同时间文件的快照保存下来，同时附加作者、时间等信息，这样就能追溯代码的历史，方便开发。Git是分布式的，这也是Git区别其他版本控制软件最本质的特征，保存在不同地方的Git仓库需要手动同步，互相之间可以毫无关系。


### Github

[GitHub](https://github.com/)是通过Git进行版本控制的软件源代码托管服务平台，由GitHub公司（曾称Logical Awesome）的开发者Chris Wanstrath、P. J. Hyett和汤姆·普雷斯顿·沃纳使用Ruby on Rails编写而成。


### Git模型

由于Git的指令设计比较拉跨，为了能清楚地理解Git，我们将从Git的`原理和模型`开始讲起。

前面我们也曾提过，所谓版本就是本文件夹的一个快照，版本控制就是管理和记录一个个快照。我们先介绍**快照的数据结构**。

#### 一个快照：树结构

考虑一个文件夹，其内容无非两种：
- 子文件夹
- 文件

并且子文件夹又可以包含新的子文件夹和文件。

这样的递归定义天然地可以用树结构进行描述。对于每个`文件`，我们用一个二进制文件对其进行储存，并称其为一个`blob`结点。而对于一个文件夹，我们用一个`tree`结点描述它。tree结点里存储了一些指向`bold`结点和子`tree`结点的“指针”。

下图是一个树结构的例子

```
<root> (tree)
|
+- foo (tree)
|  |
|  + bar.txt (blob, contents = "hello world")
|
+- baz.txt (blob, contents = "git is wonderful")
```

接下来我们研究每个结点存储什么内容才能维持住树结构。如果我们解析出`root`结点的内容，其会为

```
100644 blob 6806f5f888b8f8b813e5015b88d248c0f98be0bb    baz.txt
040000 tree d469bf0d8f677acc9f78f1b9c1893685aba8b6d9    foo
```

第一列为子节点的文件类型和权限，第二列为子节点类型。由于每个结点在存储时存成一个二进制文件，并且将其`SHA-1`哈希值作为文件的名字，故而第三列就是每个子节点实际存储时的名字，也即“指针”，第四列是子节点本身的名字。

接下来，我们解析出`bz.txt`结点(即`6806f5f888b8f8b813e5015b88d248c0f98be0bb`文件)

```
# 使用 git cat-file -p 可以解析一个结点的内容
> git cat-file -p 6806f5f888b8f8b813e5015b88d248c0f98be0bb

I'm baz, hello world!
```
其就是`baz.txt`本身的内容。


逻辑上来讲，tree结点需要完成的任务是记录这个快照的`a.txt`在哪个二进制文件里（因为不同版本的`a.txt`会保存成新的二进制文件），blob结点的任务就是记录二进制文件。下面是两个结点的伪代码

```c++
// a file is a bunch of bytes
type blob = array<byte>

// a directory contains named files and directories
type tree = map<string, tree | blob>
```

此时我们已经能记录下一个快照了。但是作为一个成熟的版本管理器，一个快照不会只包含文件内容，Git还要学会自己记录一些`meta data`(作者，信息等)，故而我们抽象出一类新结点，称为`commit`结点，其伪代码如下

```c++
// a commit has parents, metadata, and the top-level tree
type commit = struct {
    snapshot: tree 
    author: string
    parent: array<commit>
    message: string
}
```

其第一个内容为根目录对应的`tree`结点，第二行是更改者信息，第三行是这个`commit`结点的父结点们(下面马上要说到)，第四行是提交者对本次 commit 的注释信息。

下面是一个 commit 结点的内容例子

```
tree 3f6c1b5c2ee7036b295bfd9364cd025c97910a0d
parent fe3e960bf18b1f1ee85d4e3b187ef7dd2e364840
author 1600016629@pku.edu.cn <1600016629@pku.edu.cn> 
committer 1600016629@pku.edu.cn <1600016629@pku.edu.cn> 

add a line
```

注意`blob`，`tree`，`commit`结点存储时都是二进制文件并以`SHA-1`哈希值作为名字，只是保存的内容上有所差异，我们将三者统一称为`object`。

#### 快照之间：有向无环图(DAG)

接下来我们介绍下`commit`结点里的`parent`信息。一个`commit`结点的`parent`表示这个快照是在哪个快照的基础上做了改动从而产生的，它表示着各个版本的逻辑信息。注意`parent`可能是多个结点，因为比如`merge`操作会把两个`commmit`做一次合并，其父节点会是两个。

如果我们把每个`commit`当作一个点，其父子关系会定义成一个`DAG`(有向无环图)，其中`A`指向`B`表示`B是A的父节点`。

```
o <-- o <-- o <-- o
            ^
             \
              --- o <-- o
```

如果产生了`merge`，会长成下面的样子

```
o <-- o <-- o <-- o <---- o
            ^            /
             \          v
              --- o <-- o
```

我们也可以通过命令行来查看当前DAG的样子

```
# git log 会展示commit信息
> git log --all --graph --decorate --pretty=short
* commit e6ca3a087a82d04906ab19e1a58be743560bc576 (HEAD -> master)
| Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|     a modify in master branch
|
| * commit 5309e8873bdefc82cab582a0da72e691befe6daf (test)
|/  Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|       a new branch
|
* commit 7321da90372c300f2aa413d4a3e50c45bccf8d0c
| Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|     add a line
|
* commit fe3e960bf18b1f1ee85d4e3b187ef7dd2e364840
  Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>

      init
```


可以看出，此出共有4个commit(最上面的是最新的)，在第二个commit后，分成了两支。

#### 对DAG的操作

在上面的`log`信息里，我们注意到有三个东西我们不认识：

- HEAD
- master
- test

其实这三个东西是三个为用户定义的指针，称为`reference`，每个`reference` 可以指向DAG的一个结点。

首先看`master`和`test`指针，其属于两个分支`master`和`test`。前者为Git默认创建而后者是自定义的。可以看到二者分别指向了自己所在分支的`末尾`。(又或者说，正是第一次commit到分支指针的整个路径定义了这个分支)。

`HEAD`指针则是一种特殊的指针，其表示当前用户在哪里(即新的commit会是谁的儿子)。由于用户一般还要处于某个分支内，`HEAD`一般会和`master`或者`test`之一绑定，体现为log中显示`HEAD=master`而不是`HEAD,master`。此时，如果创建一个新的commit结点，`HEAD`会和`master`一起指向新的结点。

用户在版本中切换实际上就是移动`HEAD`，从而让`HEAD`指向DAG中的不同结点。操作是

```
git checkout 7321da90372c300f2aa413d4a3e50c45bccf8d0c
```

但是这样的移动不包含分支信息。一般我们是在分支之间切换，用

```
git checkout test
```

此时`HEAD`就会和`test`绑定起来。

举一个例子，对于某个Git如下

```
* commit e6ca3a087a82d04906ab19e1a58be743560bc576 (HEAD -> master, test2)
| Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|     a modify in master branch
|
| * commit 5309e8873bdefc82cab582a0da72e691befe6daf (test)
|/  Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|       a new branch
|
...
```

可见`HEAD`，`master`,`test2`都指向最上面的commit，但是`HEAD`和`master`绑定在一起。

如果我们此时提交一个新的commit，就会变成

```
* commit 058d9db895ef6f569f22c18122c4683004196c2e (HEAD -> master)
| Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|     moving master
|
* commit e6ca3a087a82d04906ab19e1a58be743560bc576 (test2)
| Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|     a modify in master branch
|
| * commit 5309e8873bdefc82cab582a0da72e691befe6daf (test)
|/  Author: 1600016629@pku.edu.cn <1600016629@pku.edu.cn>
|
|       a new branch
|
...
```

`test2`未移动，而`HEAD`和`master`一起移动，这表示`master`分支又多了一个`commit`。此时`git checkout test2`就会变回原来的版本，但是是在`test2`分支。

综上，所有的`object`和`references`组成了一个完整的Git Repository.

### Git Staging Area

到这里我们可以使用一些简单的git命令了。

拿到一个空文件夹，输入

```
> git init
```

会创建出一个`.git`的隐藏文件夹，里面包含了`objects`文件和`reference`文件以及其他。

我们创建一个新的txt文件并输入hello world

```
> echo "hello world" > a.txt
```

这就是我们想要的第一个版本了。我们想创建个此时的快照，可以使用

```
> git commit -m "init"
```

但是会报错

```
Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        a.txt

nothing added to commit but untracked files present (use "git add" to track)
```

它说你的更改没有在它的考虑范围内，如果想要让它考虑的话，需要先用`git add`将其加入。为什么Git默认不考虑更改需要手动加入呢？

因为Git的所有commit结点是无法被更改的，而很多时候，debug需要很多输出命令，他们只是暂时被需要而已，如果不管不顾地将其放入commit结点，会导致后面还需要手动删除。此外还有很多的临时文件我们并不希望纳入版本管理(比如编译链接时的中间文件)。故而我们commit时，先用add将需要纳入版本管理的更改放到`缓冲区`，然后再`commit`，其余的部分就不会进入版本管理了。

```
> git add a.txt
> git commit -m "init"
[master (root-commit) e96e3c7] init
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 a.txt
```

当然，从上面的描述我们可以看出，`git add`暂存的最小单位不应该是文件，而应该是语句。使用参数`-p`可以交互地选择某个文件中暂存哪些而忽略哪些。

由于先`add`再`commit`过于麻烦，可以用`git commit -a`代替。但是它会把所有的更改都暂存起来，此时我们需要创建一个`.gitignore`文件，里面保存我们不希望纳入版本管理的文件名即可。

同理，在创建新分支时，我们需要`git branch <branch name>`再`git checkout <branch name>`，其也可以合并成`git checkout -b <branch name>`。

### GitHub相关内容

在多人协作时，往往使用GitHub维护一个远程分支，大家都与远程分支交互。这对于Git来说和本地分支没有任何区别。

举个例子，远程主分支一般叫`origin/master`，这虽然和本地主分支`master`名字类似，但是却是不同的分支。但对于我们来讲，只需要把`origin/master`当作普通的其他分支，想要合并它的内容就使用`git merge origin/master`即可。

但是，合并之前我们需要通过网络传进来`origin/master`分支的内容，需要使用`git fetch`。

而`git fetch; git merge`等价于`git pull`。

## 服务器

服务器就是一台没有图形界面的不会关机的电脑，通常是Linux系统，与普通电脑的区别在于服务器一般需要长时间处理高并发的任务，因而在软硬件层面有针对稳定性、安全性和并发性的优化。想要远程操作服务器，一般通过**ssh**连接。

### SSH

**SSH**全称是Secure Shell Protocol，可以被用来加密任何运行在非加密网络上的服务，通常被用于远程命令行。想要使用**ssh**命令需要在本地安装SSH客户端和在服务器上安装相同版本的SSH服务端，最常用的SSH工具是[OpenSSH](https://www.openssh.com/)。在Windows下OpenSSH Client可以直接使用，但是OpenSSH Server需要在服务当中开启才能使用；而Linux一般默认包含OpenSSH，没有包含也可以直接通过包管理工具下载：
```bash
sudo apt-get install openssh-client
sudo apt-get install openssh-server
```
使用**ssh**连接服务器的一般指令为：
```bash
ssh [remote_username]@[server_ip_address]
```
其中`[remote_username]`就是服务器的IP地址，`[server_ip_address]`为服务器上的用户名，如果购买的是个人服务器可以直接登录root，如果是公用的服务器则应该使用分配的用户名。当服务器端运行着SSH server，端口22就会打开监听任何连接请求，这时本地通过ssh命令就能与服务器建立连接然后登陆对应用户。  
一般来说ssh登陆服务器需要输入用户对应的密码，但是存在使用非对称加密的登陆方法可以避免输入密码，这也是像[Gitlab](https://about.gitlab.com/)这样的网站推荐的做法。非对称加密的原理非常简单，只有拥有私钥的人才能生成签名，而任何拥有公钥的人都可以验证私钥的真实性，因此我们只需要生成一对公钥和私钥然后将公钥保存在服务器上就能向服务器证明你是谁。生成公钥和私钥对的命令是`ssh-keygen`，比如
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@domain.com"
```
就可以使用rsa算法生成4096 bits的密钥对，默认被保存在`.ssh`文件夹内：
```bash
% ls ~/.ssh

-a----          2020/9/4     11:44            177 config
-a----          2020/7/5     22:58           3243 id_rsa
-a----          2020/7/5     22:58            751 id_rsa.pub
-a----         2021/4/20     23:22            559 known_hosts
```
这里`id_rsa.pub`就是公钥。然后我们只需要将公钥复制到服务器上就可以无密码登陆了：
```bash
ssh-copy-id [remote_username]@[server_ip_address]
```

### SFTP

我们之前已经介绍过了使用VS Code的Remote-SSH插件可以将服务器内的文件夹同步到本地，实现本地与服务器之间的文件同步，但是假如我们想向服务器上传或者下载批量数据，可以考虑使用sftp命令。  
**SFTP**全程是SSH File Transfer Protocol，也就是SSH封装的FTP服务。在sftp之前还有scp用于传输文件，scp同样基于SSH，二者最大的区别在于SCP不支持断点续传，而SFTP支持。  
SFTP的使用方法与SSH非常类似，首先我们需要与服务器建立连接：
```bash
sftp [remote_username]@[server_ip_address]
```
然后我们就会进入sftp命令行，可以输入`ls`、`mkdir`、`cp`等命令操作远程文件，在这些命令前加上`l`就能操作本地的文件，比如`lls`、`lmkdir`等等。想要下载某个文件时就可以：
```bash
get remoteFile <localFile>
```
想要上传某个文件时就可以
```bash
put localFile <remoteFile>
```
这里的文件名自然支持通配符因而支持批量操作。想要上传或下载整个文件夹时只需要在前面加上`-r`，如果同时想保留文件权限可以`-Pr`。  
一些图形化客户端也可以为互传文件提供便利，比如[WinSCP](https://winscp.net/eng/docs/lang:chs)、[Filezilla](https://www.filezilla.cn/)等等。

## 网络代理

由于一些众所周知的原因，我们需要通过代理才能访问Google，想要科学上网我们首先要了解一下有关代理的基础知识。  
代理(Proxy)是在客户端和目标服务器中间插入一个代理服务器，所有来自客户端的请求都会通过代理服务器的转发从而实现匿名的目的。现在常用的代理方式有两种：http代理和socks5代理。http代理是在http协议的框架下，所有数据都采用http包的形式交换；socks5代理相比于http代理更为底层，没有协议和端口的限制，因而泛用性更强。理论上我们只需要有一个国外的服务器并且服务器能够访问到外网，就可以把它作为代理服务器访问到外网，实现这一功能最常用的工具是[shdowsocks](https://shadowsocks.org/en/index.html)。  
shadowsocks同样分为客户端sslocal和服务器端ssserver，sslocal可以在本地开启一个socks5代理端口，ssserver则会在代理服务器上打开一个监听端口，然后不断在两个端口之间传递数据。shadowsocks通过json文件来配置代理信息。在服务器端的配置文件（一般位于`/etc/shadowsocks/server.json`）里写入
```json
{
    "server": "0.0.0.0", 
    "server_port": 1851,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "xxxxx",
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": false
}
```
然后就可以通过
```bash
ssserver -c /etc/shadowsocks-server.json -d start
```
打开代理服务器的监听端口，本地的配置类似：
```json
{
    "server": "xxx.xxx.xxx.xxx",
    "server_port": 1851,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "xxxxxx",
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": false
}
```
通过
```bash
sslocal -c /etc/shadowsocks/client.json -d start
```
打开本地的代理端口。理论上这时就完成了代理的配置，可以通过curl命令检查代理配置是否成功：
```bash
curl --socks5-hostname localhost:1080 http://www.google.com/
```
但是我们还需要最后一步，就是修改浏览器、git等工具的默认设置，使其默认通过代理服务器连接到网络。对于Chrome和Firefox浏览器有非常方便的插件比如[Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif)实现代理配置，git等工具则可通过命令行
```bash
git config --global http.proxy 'socks5://127.0.0.1:1080'
git config --global https.proxy 'socks5://127.0.0.1:1080'
```
来完成代理配置。注意这里的端口号与上面本地配置一致，可以用户自己选择，但是要尽量避免冲突，比如22就不是一个好的端口号，而8888、9999这样都没有问题。  
如果想要使用shadowsocks进行http代理（一些浏览器和工具只支持http代理），则可借助其他工具比如[privoxy](https://www.privoxy.org/)再在本地打开一个http代理的端口转发给shdowsocks的socks5端口。

如果是自己购买的VPS(Virtual Private Server)搭建代理服务器一般价格便宜带宽高，但是存在一定的风险，因为一个服务器只能对应一个IP地址，如果IP地址被封禁就只能更换服务器。因此一般的做法是购买SS/SSR服务，提供商配置多个代理服务器增加容错几率，对应的代价就是流量受限且有的价格昂贵。  
介绍到这里我们并没有提到大家可能更为熟悉概念——VPN。VPN全程是Virtual Private Network，虚拟私人网络，从名字也可以看出VPN是为了保护用户隐私而设计出来的，并不是针对翻墙而提出的，其发明也早于GFW。由于其隐私特性，大家普遍使用VPN来翻墙，网络上也出现了大量VPN服务提供商。但是不同于shadowsocks，不同供应商之间的网络并不互通，因而购买一家的服务之后只能通过这一家提供的软件、服务器使用。而且VPN的流量特征过于明显因而很容易被发现，所以并不推荐大家使用。


## 个人网站

搭建一个个人网站是听起来很Geek的事情，对于科研工作者来说也是必要的事情，因为这是别人了解你的研究的第一步。下面我们就从简单到复杂一步一步搭建一个个人网站出来。  
首先我们需要明白网站是如何工作的。一个最简单的网站可以只包含一个html文件：
```html
<!DOCTYPE html>
<html>
<head>
<title>Page Title</title>
</head>
<body>

<h1>This is a Heading</h1>
<p>This is a paragraph.</p>

</body>
</html>
```
HTML全程是Hypertext Markup Language，是描述网页的基本语言，可以看到其中有标题`<title>`，有段落`<p>`等等，这样一个网页文件被保存在服务器上，当有网站的访问请求时，就可以通过网站后端把网页文件传输到客户端，然后在本地的浏览器中被渲染出来。这样一个传输过程通过的是HTTP网络协议。站在客户端的角度，我们在浏览器中输入一个网址，这个网址首先要通过DNS服务器转变为IP地址，然后才将网站请求发送到目标服务器的HTTP端口上（一般是80）。因此我们可以看到想要创建上面这个简单的可访问的网页，我们至少需要一个服务器，一个网站后端和一个域名。  
这听起来很麻烦，但是幸运的一点是，每个Github用户都可以免费创建一个[Github Page](https://pages.github.com/)，域名为`<user-name>.github.io`，使用的是Github提供的服务器和后端。因而使用Github搭建个人网站变得非常简单，我们只需要两步：

* 创建一个名称为`<user-name>.github.io`的空项目
* 在项目中加入上面的html文件，命名为`index.html`

Push上去之后直接访问`<user-name>.github.io`就可以看到渲染出来的html文件。接下来的工作，只需要替换html文件里的内容为自己的照片、简介、研究内容，一个简单的个人网站就完成了。  
单纯的html功能显然有限，排版简陋，没有交互，不方便修改，想让个人网站看起来更高端大气就需要html的两个兄弟——css和JavaScript。css是html的风格化文件，可以定义html中各个元素的相对位置以及如何渲染（~~比如小米的新logo就是通过修改css文件让方角变圆角~~）；JavaScript则是一个脚本语言，可以从html中得到用户输入的信息，处理之后修改html中的内容。HTML、CSS、JavaScript也就是大家常说的网站的前端部分，定义了网站长什么样子以及如何响应用户的输入。然而除非大家对前端设计非常感兴趣，一般来说我们可以使用开源的前端框架就可以直接生成美观的网站，而不需要手动修改css和JavaScript。  

> JavaScript和Java可以说是毫无关系。
> 使用裸html为自己创建个人网站颇有大佬风格，网站不好看没关系，研究做得漂亮就行了。

对于个人网站的一般需求，大家常使用静态博客的前端框架生成自己的网站，比如[hexo](https://hexo.io/)，[Jekyll](https://jekyllrb.com/)，[hugo](https://gohugo.io/)等等。这一类框架提供了Markdown渲染为网页的功能，用户使用Markdown写作博客，网站会自动将文章按照用户定义的标签进行分类展示到网站上。同时每一种框架都提供了很多模板供大家选择，可以很轻松地在不修改网站内容的情况下切换主题。  
如果觉得Github上搭建的网站还不能满足的要求的话，可以考虑购买服务器或者树莓派，自己搭建网站后端，这里就不过多介绍了。

## 一些有用的工具

* [OneTab](https://www.one-tab.com/)是一个浏览器插件，如果打开的页面过多占用很高的内存，但又想保留防止之后找不到时，可以考虑使用。它可以将所有打开页面的网址保存在一起然后关闭所有页面，并且可以随时一键恢复所有网页，这在写论文时非常有用。
* [Paste Image](https://github.com/mushanshitiancai/vscode-paste-image)是一个VS Code插件，当我们想在Markdown中插入剪切板中的图片时，可以使用这个插件一步完成，剪切板中的图片会自动保存到用户指定的目录下然后在Markdown中创建引用指向图片，这在整理笔记时尤其有用。
* [Code Snap](https://github.com/kufii/CodeSnap)是一个VS Code插件，可以将代码块保存为图片，方便在文档报告中插入美观的代码。
* [Bracket Pair Colorizer](https://github.com/CoenraadS/Bracket-Pair-Colorizer-2)是一个VS Code插件，可以将不同层次的括号以不同颜色显示，方便代码阅读。
* [github1s](https://github.com/conwnet/github1s)是一个Github的小trick，当我们浏览一个Github项目代码又不想下载下来阅读时，可以考虑为Github加1s，这样就可以在浏览器中在线以VS Code风格阅读代码。
* [Grammarly](https://app.grammarly.com/)是一个语法检查网站，基础功能是免费的，如果需要发送一封正式的邮件或者写英文论文，都可以先使用Grammarly检查一下。