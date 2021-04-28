---
title: 前沿计算实践II
---

# Lecture 4: Python

## Python

**Python**是一门解释型语言，区别于编译型语言比如C。C编译器会预先将C代码编译成机器语言的可执行文件，之后就可以直接将可执行文件载入内存运行；但是Python代码（无论是命令行中的还是.py脚本中的）都会先被转化为跨平台的中间二进制代码，然后再经过Python虚拟机执行。这样的好处是虚拟机可以自动判断变量类型，同时完成处理依赖、垃圾回收等等工作，而不需要使用者操心，相应的代价就是运行时相比于编译型语言要慢很多。  

> 除了`.py`文件，运行python代码时经常会看到`__pycache__`，`.pyc`，`.pyo`，`.pyd`等文件，这些文件（夹）都是python解释的中间文件，用于加速python代码的加载过程，但是并不能加速运行过程，因而可以直接忽略，在git同步时一般也会在`.gitignore`中标明这些文件

但实际上这只是[CPython](https://github.com/python/cpython)的解释过程。CPython是默认的Python解释器，使用C编写。其他的Python解释器一部分如下：

* [IPython](https://ipython.org/)是基于CPython的交互解释器，因而执行代码的能力与CPython完全一样，但是在交互上更为智能
* [PyPy](https://www.pypy.org/)不同于CPython，使用Just-In-Time(JIT) Compilation技术能够加速Python代码的执行，但是在某些情况下相同Python代码在两种解释器下会有不同的结果，并且PyPy支持的Python语言版本比CPython相对滞后
* [Jython](https://www.jython.org/)是Python的[Java](https://www.java.com)实现
* [IronPython](https://ironpython.net/)是Python在微软[.NET](https://dotnet.microsoft.com/)平台的实现

## PIP

[PIP](https://pypi.org/project/pip/)是Python默认的包管理工具，与我们之前介绍的`apt-get`非常类似，只不过pip使用[Python Package Index](https://pypi.org/)源来下载安装Python包。与`apt-get`类似，如果发现在国内下载速度过慢时可以使用[清华源](https://mirrors.tuna.tsinghua.edu.cn/help/pypi/)来加速。  
如果在Ubuntu系统下运行`man pip`，可以看到这样一段话：

> pip is a Python package installer, recommended for installing Python packages which are not available in the Debian archive.

这里这么说的原因在于一些Python包能够通过多种途径安装，比如[NumPy](https://numpy.org/install/)：
```
pip3 install numpy
sudo pip3 install numpy
sudo apt install python3-numpy
```
这三种安装方法会把NumPy安装在不同的位置，可以分别用`pip show`和`sudo pip show`查看：
```
/home/<user-name>/.local/lib/python3.8/site-packages
/usr/local/lib/python3.8/dist-packages
/usr/lib/python3/dist-packages
```
我们可以通过它们所在的位置看出差别，第一种方法安装的位置在用户的个人目录下，因此不能被其他用户看到；第二种方法所有用户都能看到，但是被安装在`python3.8`下，因此其他版本的Python3就不能import这个包；第三种方法安装的包则可以被所有用户和所有Python3的版本看到。使用`apt`安装的包同时会在`apt upgrade`时更新，安装时间也更短，打开`/usr/lib/python3/dist-packages`目录也可以发现系统预装的Python包都在这个目录下，因此没有特殊原因使用`apt`安装Python包更好。当然如果是在**虚拟环境**下或者需要安装**特定版本**的包，使用pip更合适。

> 好的包管理是一门语言成功的部分，[Ruby](https://www.ruby-lang.org/en/)的包管理工具是[gem](https://rubygems.org/gems)，[Javascript](https://www.javascript.com/)的包管理是[npm](https://www.npmjs.com/)

## Version Management

Python在Python2（已经停止更新）和Python3两个大版本之下存在很多小的版本，虽然Python更新时一般会向前兼容，但是仍然存在一些API被抛弃，因而一台机器上往往会存在多个版本的Python。Ubuntu提供了`update-alternatives`来管理一个命令的不同版本，我们可以用这个命令来方便地管理Python。假设我们已经安装了Python3.7和Python3.8分别位于`/usr/bin/python3.7`和`/usr/bin/python3.8`，首先需要在Python的替换选项中注册它们：
```
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 2
```
`update-alternatives`通过软连接来实现版本替换，这里我们设定的就是软连接。`/usr/bin/python`是软连接的入口，它会指向`/etc/alternatives/python`，然后再指向`usr/bin/python3.8`或者`usr/bin/python3.7`。命令的最后一个数字是优先级，数字越大优先级越高，在自动模式下会链接到优先级最高的版本，想要切换版本时直接
```
sudo update-alternatives --config python
```
就可以在不同的版本之间选择了。`update-alternatives`还支持分组管理，但是用得比较少这里就不再赘述。

Python有非常多第三方的包，使用它们大大提高了效率，但是也非常容易导致版本冲突问题。冲突的原因是软件包往往会在大版本更新时更改之前的部分API，使用旧的API编写的程序在新版本下就无法运行。出于这个原因，一般来说项目开发时会固定使用某个版本的包，并且把用到的包的版本通过`requirements.txt`文件记录下来：
```
wheel==0.23.0
Yarg==0.1.9
docopt==0.6.2
```
这样别人使用这个项目时就可以知道需要安装哪个版本的包不会导致冲突了。`requirements.txt`并不需要手动生成，可以使用pip自动生成：
```
pip freeze > requirements.txt
```
这样就可以把依赖包的版本固定下来。这样做唯一的问题是这个命令会把所有的包的版本记录下来，包括那些项目并未使用的包，这时可以使用[pigar](https://github.com/Damnever/pigar)，[pipreqs](https://github.com/bndr/pipreqs)这样的命令代替。有了`requiresments.txt`之后，当别人使用这个项目时就可以使用
```
pip install -r requirements.txt
```
来一键安装所需要版本的包了。

> 这一过程不一定要在命令行下完成，一些Python IDE比如[Pycharm](https://www.jetbrains.com/pycharm/)提供了处理`requirements.txt`的图形界面功能

## Virtual Environment

一台电脑上一般要运行多个Python项目，为每个项目创建一个虚拟环境是非常自然的想法。创建虚拟环境的工具非常多，我们选取三个最有代表性的工具介绍：

* [virtualenv](https://virtualenv.pypa.io/en/latest/)：最轻量的虚拟环境工具，在项目目录下创建
* [Anaconda](https://www.anaconda.com/)：包含了虚拟环境和包管理，统一管理虚拟环境
* [Docker](https://www.docker.com/)：基本等价于轻量的虚拟机，不局限于Python

这三个工具从简单到复杂能够覆盖不同场景下的需求。

### virtualenv

`virutalenv`是Python的一个包，可以通过`pip`来安装，当然正如之前所说也可以使用`apt`安装：
```
sudo apt install python3-virtualenv
```
当我们想要创建一个虚拟环境时，直接
```
virtualenv example
```
这时就会在当前目录下创建一个名为`example`的文件夹，打开就可以发现有如下的文件：
```
$ exa --tree --level=2
.
├── bin
│  ├── activate
│  ├── activate.csh
│  ├── activate.fish
│  ├── activate.ps1
│  ├── activate.xsh
│  ├── activate_this.py
│  ├── chardetect
│  ├── chardetect-3.8
│  ├── chardetect3
│  ├── distro
│  ├── distro-3.8
│  ├── distro3
│  ├── easy_install
│  ├── easy_install-3.8
│  ├── easy_install3
│  ├── f2py
│  ├── f2py3
│  ├── f2py3.8
│  ├── pip
│  ├── pip-3.8
│  ├── pip3
│  ├── pip3.8
│  ├── python -> /usr/bin/python3
│  ├── python3 -> python
│  ├── python3.8 -> python
│  ├── wheel
│  ├── wheel-3.8
│  └── wheel3
├── lib
│  └── python3.8
└── pyvenv.cfg
```
可以发现在`bin`的目录下自动安装了`pip`，并将`python`指向了系统当前的Python路径。`virtualenv`直接创建的虚拟环境会使用系统的Python版本，因此如果在之后修改了系统Python的版本（比如通过`update-alternatives`）可能会导致虚拟环境的冲突，但是在虚拟环境外使用`pip`更新包的版本不会导致冲突，因为`virtualenv`在虚拟环境下单独安装了一个`pip`，并将虚拟环境中的包独立保存在了`lib`目录下。如果不想使用系统默认的Python版本创建环境时，也可以使用`--python`后缀指定Python的路径。打开虚拟环境只需要：
```
source bin/active
```
此时如果使用`bash`的话可以在命令提示前出现`(example)`提示，我们可以使用`which python`和`which pip`来检验虚拟环境确实被打开了，此时使用`pip`安装任何包都会与系统环境隔离开。想要关闭虚拟环境只需要
```
deactivate
```

### Conda

Conda现在是最主流的Python虚拟环境管理工具，提供GUI，可以和多种编辑器和IDE方便地对接，并且在Windows下使用也非常方便。在有GUI的电脑上可以安装Anaconda或者Miniconda的GUI版本，在服务器上则可以通过官方脚本安装
```
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init bash
~/miniconda3/bin/conda init zsh
```

使用`conda`命令创建虚拟环境与`virtualenv`非常类似：
```
conda create --name py38 python=3.8
```
这里的区别在于这个环境会被安装到Conda默认的目录`<conda-path>/envs`下（也可以用户指定），并且这个环境中会独立安装一个Python。激活这个虚拟环境的命令是：
```
conda activate py38
```
Conda在安装之后会默认创建一个名为`base`的环境，并且如果设置了`conda init bash`会在bash启动时默认打开，详细设置可以查看`~/.bashrc`。Conda除了创建虚拟环境之外还可以作为独立于`pip`之外的包管理器，使用方法就是`conda install`、`conda update`和`conda remove`。既然是包管理器，发现速度过慢时同样可以配置[清华源](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/)。最后关闭虚拟环境使用
```
conda deactivate
```

### Docker

Docker相比于上面两种虚拟环境工具要复杂得多，使用容器承载应用程序，实现类似虚拟机的效果。很多开源的项目会提供Docker镜像供使用者下载，就可以避免用户自己安装环境，相应的代价就是所需的硬盘空间会更大。这里我们仅展示一个使用Docker为Python创建虚拟环境的简单例子。  
Docker可以通过官方脚本安装（使用apt可能会装到旧版本）
```
curl -fsSL https://get.docker.com | bash -s docker
```
Docker官方提供了镜像源[Docker Hub](https://hub.docker.com/)，我们可以直接从这个源安装特定版本的Python镜像：
```
sudo docker pull python:3.5
```
安装下来的镜像可以通过`image`命令查看
```
sudo docker image ls
```
注意这里我们安装的东西远不止Python，事实上我们可以直接进入这个镜像的命令行环境
```
sudo docker run -it python:3.5 /bin/bash
```
在这个环境下就会发现Python的版本变成了3.5。我们可以修改命令后面的`/bin/bash`就可以使用Docker运行其他命令，同时可以通过`-v`指定镜像挂载的目录和`-w`指定工作目录。


## Jupyter Notebook

[Jupyter Notebook](https://jupyter.org/)的前身是[IPython Notebook](http://ipython.org/index.html)，正如之前所说IPython是基于CPython的解释器，而Jupyter Notebook则是利用浏览器为IPython打造了一个交互的GUI界面，将图片、代码、文字、公式组织成了一个动态可交互的电子书。Jupyter这个名字来源于所支持的语言：[Julia](https://julialang.org/)，Python和[R](https://www.r-project.org/)。  
Jupyter Notebook相比与直接使用Python的优势是显而易见的，分块式的代码方便实现和debug，输出中间结果非常方便，同时代码中间可以穿插文字和图片辅助说明，所有这一切使用JSON文件格式组织起来打包为一个`.ipynb`文件。随便用记事本打开一个`.ipynb`文件就会发现里面无非就是字符串形式储存的代码、文字和二进制格式的图片，Jupyter Notebook相当于就是提供了一个渲染、调用Python修改这个文件的GUI。

> 实际上Jupyter Notebook借鉴了Matlab的[Live Editor](https://www.mathworks.com/products/matlab/live-editor.html)，后者也非常好用

Jupyter Notebook可以直接通过`pip`安装：
```
pip install jupyter
```
安装完成之后在任何一个目录下运行`jupyter notebook`就可以在浏览器中打开该目录，然后运行`.ipynb`文件了。如果是在服务器上，可以`jupyter notebook --ip 0.0.0.0 --port 8888`，然后远程访问`<server-ip>:8888`并输入服务器上显示的token就可以像本地一样使用了。

### Widget

[ipywidget](https://ipywidgets.readthedocs.io/en/latest/index.html)是基于HTML的Jupyter Notebook的GUI小组件，可以通过widget为notebook添加按钮、选项框、按钮等交互功能，而不用使用[Qt](https://www.qt.io/)等更为底层的GUI框架。比如我们想让使用者选择一个1-10之间的整数作为输入然后计算输出，就可以首先创建一个滑动条
```python
import ipywidgets as widgets
from IPython.display import display
slider = widgets.IntSlider(min=1,max=10,step=1)
display(slider)
```
然后创建一个按钮
```python
btn = widgets.Button(description='compute')
display(btn)
```
最后在按钮的回调函数里得到输入并计算结果
```python
def btn_eventhandler(arg):
    input = slider.value
    # process input to get result
    print(result)

btn.on_click(btn_eventhandler)
```
这时notebook就可以变成一个带GUI的小应用了。

### Matplotlib

[Matplotlib](https://matplotlib.org/)是Python的画图工具，一般用来绘制二维图形，如果想要在Jupyter Notebook的环境下绘制三维图形或者可交互的二维图形，可以使用[ipympl](https://github.com/matplotlib/ipympl)工具。事实上，Matplotlib只是提供了一个画图的前端接口，具体画线、画点是由后端解决的，在一般Python程序中弹出的绘图窗口使用的一般是Qt的后端，想要在Notebook中画图就得依赖ipympl后端，使用的是ipywidgets的框架。具体的使用方法非常简单，首先安装ipympl包，然后在代码中插入
```
%matplotlib widget
```
就可以使用了。值得注意的是Jupyter在内核启动之后只能使用一个画图后端，所以如果发现widget出现了一些问题想要换成`%matplotlib qt`或者`matplotlib notebook`等，需要重启Jupyter。

### VS Code & Jupyter Lab

正如我们之前介绍的，VS Code本质上是一个浏览器，因而Jupyter Notebook可以方便地在VS Code里使用。VS Code提供了[Jupyter](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)官方插件（2020年底），得益于VS Code其他插件的支持，在VS Code中使用Jupyter Notebook会比在其他网页里体验更好。此外，VS Code提供了另一个非常有用的功能，在正常`.py`中插入`# %%`可以自动把代码组织成代码块，点击`运行单元`就可以在旁边打开一个Notebook交互界面，同时支持`.py`文件和`.ipynb`文件的相互转换。Jupyter Notebook项目官方也提供了类似VS Code的多功能Notebook编辑工具[Jupyter Lab](https://github.com/jupyterlab/jupyterlab)，为Notebook提供了更多支持。


## References

* [How does Python work](https://towardsdatascience.com/how-does-python-work-6f21fd197888)
* [Differences Between .pyc, .pyd, and .pyo Python Files](https://stackabuse.com/differences-between-pyc-pyd-and-pyo-python-files/)
* [What’s Better? Anaconda or Python Virtualenv](https://dataaspirant.com/anaconda-python-virtualenv/)
* [IPython Or Jupyter?](https://www.datacamp.com/community/blog/ipython-jupyter)

