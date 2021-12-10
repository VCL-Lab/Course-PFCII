---
title: 前沿计算实践I
---

# Lecture 4: Build System & Python+Cpp 



Python写起来非常方便, 但面对大量for循环的时候, 执行速度有些捉急. 原因在于, python是一种动态类型语言, 在运行期间才去做数据类型检查, 这样效率就很低(尤其是大规模for循环的时候).

相比而言, C/C++每个变量的类型都是事先给定的, 通过编译生成二进制可执行文件. 相比与python, C/C++效率比较高, 大规模for循环执行速度很快. 

既然python的短板在于速度, 所以, 为了给python加速, 能否在Python中调用C/C++的代码? 

### Python解释器

当我们编写Python代码时，我们得到的是一个包含Python代码的以`.py`为扩展名的文本文件。要运行代码，就需要Python解释器去执行`.py`文件。

(你给我翻译翻译, 什么叫python代码)

#### CPython

当我们从[Python官方网站](https://www.python.org/)下载并安装好Python后，我们就直接获得了一个官方版本的解释器：`CPython`。这个解释器是用C语言开发的，所以叫`CPython`。在命令行下运行`python`就是启动`CPython`解释器。`CPython`是使用最广的Python解释器。

虽然CPython效率低, 但是如果用它去调用C/C++代码, 效果还是挺好的. 像numpy之类的数学运算库, 很多都是用C/C++写的. 这样既能利用python简洁的语法, 又能利用C/C++高效的执行速度, (赢了两次, 赢麻了). 有些情况下numpy效率比自己写C/C++还高, 因为numpy利用了CPU指令集优化和多核并行计算(又赢了两次).

我们今天要讲的Python调用C/C++, 都是基于CPython解释器的.

#### IronPython

`IronPython`和`Jython`类似，只不过`IronPython`是运行在微软`.Net`平台上的`Python`解释器，可以直接把Python代码编译成.Net的字节码。缺点在于, 因为`numpy`等常用的库都是用`C/C++`编译的, 所以在`IronPython`中调用`numpy`等第三方库非常不方便.

#### Jython

`Jython`是运行在`Java`平台上的`Python`解释器，可以直接把`Python`代码编译成`Java`字节码执行。`Jython`的好处在于能够调用`Java`相关的库, 坏处跟`IronPython`一样.

#### PyPy

PyPy一个基于Python的解释器，也就是用python解释.py. 它的目标是执行速度。PyPy采用[JIT技术](http://en.wikipedia.org/wiki/Just-in-time_compilation)，对Python代码进行动态编译（注意不是解释），所以可以显著提高Python代码的执行速度。

### 为什么动态解释慢

假设我们有一个简单的python函数

```python
def add(x, y):
	return x + y
```

然后`CPython`执行起来大概是这个样子(伪代码)

```c
if instance_has_method(x, '__add__') {
    // x.__add__ 里面又有一大堆针对不同类型的 y 的判断
    return call(x, '__add__', y);
} else if isinstance_has_method(super_class(x), '__add__' {
    return call(super_class, '__add__', y);
} else if isinstance(x, str) and isinstance(y, str) {
    return concat_str(x, y);
} else if isinstance(x, float) and isinstance(y, float) {
    return add_float(x, y);
} else if isinstance(x, int) and isinstance(y, int) {
    return add_int(x, y);
} else ...
```

因为Python的动态类型, 一个简单的函数, 要做很多次类型判断. 这还没完，你以为里面把两个整数相加的函数，就是 C 语言里面的 x + y 么? No.

Python里万物皆为对象, 实际上Python里的int大概是这样一个结构体(伪代码).

```c
struct {
    prev_gc_obj *obj
    next_gc_obj *obj
    type IntType
    value IntValue
    ... other fields
}
```

每个 int 都是这样的结构体，还是动态分配出来放在 heap 上的，里面的 value 还不能变，也就是说你算 1000 这个结构体加 1000 这个结构体，需要在heap里malloc出来 2000 这个结构体. 计算结果用完以后, 还要进行内存回收. (执行这么多操作, 速度肯定不行)

所以, 如果能够静态编译执行+指定变量的类型, 将大幅提升执行速度.

## cython

### 什么是cython

cython是一种新的编程语言, 它的语法基于python, 但是融入了一些C/C++的语法. 比如说, cython里可以指定变量类型, 或是使用一些C++里的stl库(比如使用`std::vector`), 或是调用你自己写的C/C++函数.

注意: Cython不是CPython!

### 原生Python

我们有一个`RawPython.py`

```python
from math import sqrt
import time

def func(n):
    res = 0
    for i in range(1, n):
        res = res + 1.0 / sqrt(i)
    return res

def main():
    start = time.time()
    res = func(30000000)
    print(f"res = {res}, use time {time.time() - start:.5}")

if __name__ == '__main__':
    main()
```

我们先使用Python原生方式来执行看一下需要多少时间。



### 编译运行Cython程序

首先, 把一个cython程序转化成`.c/.cpp`文件, 然后用`C/C++`编译器, 编译生成二进制文件. 在Windows下, 我们需要安装Visual Studio/mingw等编译工具. 在Linux或是Mac下, 我们需要安装`gcc`, `clang` 等编译工具.

1. 通过`pip`安装cython

   ```shell
   pip install cython
   ```

   

2. 把`RawPython.py`重命名为`RawPython1.pyx`

3. (1)用setup.py编译

   增加一个`setup.py`, 添加以下内容. 这里language_level的意思是, 使用Python 3.

   ```python
   from distutils.core import setup
   from Cython.Build import cythonize
   
   setup(
       ext_modules = cythonize('RawPython1.pyx', language_level=3)
   )
   ```

   把Python编译为二进制代码

   ```shell
   python setup.py build_ext --inplace
   ```

   然后, 我们发现当前目录下多了RawPython1.c(由`.pyx`转化生成), 和`RawPython1.pyd`(由.c编译生成的二进制文件). 

   (2)直接在命令行编译(以`gcc`为例)

   ```shell
   cython RawPython1.pyx
   gcc -shared -pthread -fPIC -fwrapv -O2 -Wall -fno-strict-aliasing -I/usr/include/python3.x -o RawPython1.so RawPython1.c
   ```

   第一句是把.pyx转化成.c, 第二句是用`gcc`编译+链接.

4. 在当前目录下, 运行

   ```shell
   python -c "import RawPython1; RawPython1.main()"
   ```

   我们可以导入编译好的RawPython1模块, 然后在Python中调用执行.

   

由以上的步骤的执行结果来看，并没有提高太多，只大概提高了一倍的速度，这是因为Python的运行速度慢除了因为是解释执行以外还有一个最重要的原因是Python是动态类型语言，每个变量在运行前是不知道类型是什么的，所以即便编译为二进制代码同样速度不会太快，这时候我们需要深度使用`Cython`来给Python提速了，就是使用`Cython`来指定Python的数据类型。

### 加速!加速!

#### 指定变量类型

cython的好处是, 可以像C语言一样, 显式地给变量指定类型. 所以, 我们在`cython`的函数中, 加入循环变量的类型. 

然后, 用C语言中的sqrt实现开方操作. 

```cython
def func(int n):
    cdef double res = 0
    cdef int i, num = n
    for i in range(1, num):
        res = res + 1.0 / sqrt(i)
    return res
```

但是, python中`math.sqrt`方法, 返回值是一个`Python`的`float`对象, 这样效率还是比较低.

为了, 我们能否使用C语言的sqrt函数? 当然可以~

`Cython`对一些常用的C函数/C++类做了包装, 可以直接在Cython里进行调用.

我们把开头的

```python
from math import sqrt
```

换成

```cython
from libc.math cimport sqrt
```

再按照上面的方式编译运行, 发现速度提高了不少.



#### Cython调用C/C++

既然C/C++比较高效, 我们能否直接用cython调用C/C++呢? 就是用C语言重写一遍这个函数, 然后在cython里进行调用.

首先写一段对应的C语言版本

usefunc.h

```c
#pragma once
#include <math.h>
double c_func(int n)
{
	int i;
	double result = 0.0;
	for(i=1; i<n; i++)
		result = result + sqrt(i);
	return result;
}
```

然后, 我们在`Cython`中, 引入这个头文件, 然后调用这个函数

```cython
cdef extern from "usecfunc.h":
    cdef double c_func(int n)
import time

def func(int n):
    return c_func(n)

def main():
    start = time.time()
    res = func(30000000)
    print(f"res = {res}, use time {time.time() - start:.5}")
```

#### 在Cython中使用numpy

在`Cython`中, 我们可以调用`numpy`. 但是, 如果直接按照数组下标访问, 我们还需要动态判断`numpy`数据的类型, 这样效率就比较低. 

```cython
import numpy as np
cimport numpy as np
from libc.math cimport sqrt
import time

def func(int n):
    cdef np.ndarray arr = np.empty(n, dtype=np.float64)
    cdef int i, num = n 
    for i in range(1, num):
        arr[i] = 1.0 / sqrt(i)
    return arr

def main():
    start = time.time()
    res = func(30000000)
    print(f"len(res) = {len(res)}, use time {time.time() - start:.5}")
```

解释:

```cython
cimport numpy as np
```

这一句的意思是, 我们可以使用`numpy`的C/C++接口(指定数据类型, 数组维度等).



```cython
import numpy as np
```

这一句的意思是, 我们也可以使用`numpy`的Python接口(np.array, np.linspace等). `Cython`在内部处理这种模糊性，这样用户就不需要使用不同的名称.



在编译的时候, 我们还需要修改setup.py, 引入`numpy`的头文件.

```python
from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy as np

setup(ext_modules = cythonize(
    Extension("RawPython4", ["RawPython4.pyx"],include_dirs=[np.get_include()],), 
    language_level=3)
)
```



##### 加速!加速!

上面的代码, 还是能够进一步加速的

1. 可以指定`numpy`数组的数据类型和维度, 这样就不用动态判断数据类型了. 实际生成的代码, 就是按C语言里按照数组下标来访问.

2. 在使用numpy数组时, 还要同时做数组越界检查. 如果我们确定自己的程序不会越界, 可以关闭数组越界检测.

3. Python还支持负数下标访问, 也就是从后往前的第`i`个. 为了做负数下标访问, 也需要一个额外的if..else..来判断. 如果我们用不到这个功能, 也可以关掉.

4. Python还会做除以0的检查, 我们并不会做除以0的事情, 关掉.

5. 相关的检查也关掉.



最终加速的程序如下:

```cython
import numpy as np
cimport numpy as np
from libc.math cimport sqrt
import time
cimport cython

@cython.boundscheck(False)         # 关闭数组下标越界
@cython.wraparound(False)          # 关闭负索引
@cython.cdivision(True)            # 关闭除0检查
@cython.initializedcheck(False)    # 关闭检查内存视图是否初始化
def func(int n):
    cdef np.ndarray[np.float64_t, ndim=1] arr = np.empty(n, dtype=np.float64)
    cdef int i, num = n 
    for i in range(1, num):
        arr[i] = 1.0 / sqrt(i)
    return arr

def main():
    start = time.time()
    res = func(30000000)
    print(f"len(res) = {len(res)}, use time {time.time() - start:.5}")
```



```cython
cdef np.ndarray[np.float64_t, ndim=1] arr = np.empty(n, dtype=np.float64)
```

这一句的意思是, 我们创建numpy数组时, 手动指定变量类型和数组维度.



上面是对这一个函数关闭数组下标越界, 负索引, 除0检查, 内存视图是否初始化等. 我们也可以在全局范围内设置, 即在.pyx文件的头部, 加上注释

```cython
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
# cython: initializedcheck=False
```



也可以用这种写法:

```cython
with cython.cdivision(True):
	# do something here
```



#### 其他

cython吸收了很多C/C++的语法, 也包括指针和引用. 也可以把一个struct/class从C++传给Cython. 

#### 总结

Cython的语法与Python类似, 同时引入了一些C/C++的特性, 比如指定变量类型等. 同时, Cython还可以调用C/C++的函数. 

Cython的特点在于, 如果没有指定变量类型, 执行效率跟Python差不多. 指定好类型后, 执行效率才会比较高.

更多文档可以参考Cython官方文档 http://docs.cython.org/en/latest/index.html

## pybind11

`Cython`是一种类`Python`的语言, 但是`pybind11`是基于`C++`的. 我们在.cpp文件中引入pybind11, 定义python程序入口, 然后编译执行就好了.

从官网的说明中看到pybind11的几个特点

- 轻量级头文件库
- 目标和语法类似于优秀的Boost.python库
- 用于为python绑定c++代码

#### 安装

可以执行`pip install pybind11`安装 pybind11 (万能的pip)

也可以用Visual Studio + vcpkg+CMake来安装(yhy之后会讲).

#### 简单的例子

```C++
#include <pybind11/pybind11.h>

namespace py = pybind11;
int add_func(int i, int j) {
    return i + j;
}

PYBIND11_MODULE(example, m) {
    m.doc() = "pybind11 example plugin";  //可选，说明这个模块是做什么的
    m.def("add_func", &add_func, "A function which adds two numbers");
}
```

首先引入pybind11的头文件, 然后用PYBIND11_MODULE声明.

- example：模型名，切记不需要引号. 之后可以在python中执行`import example`

- m：可以理解成模块对象, 用于给Python提供接口

- m.doc()：help说明

- m.def：用来注册函数和Python打通界限

```c++
m.def( "给python调用方法名"， &实际操作的函数， "函数功能说明" ). //其中函数功能说明为可选
```



#### 编译&运行

pybind11只有头文件，所以只要在代码中增加相应的头文件, 就可以使用pybind11了.

```c++
#include <pybind11/pybind11.h>
```



1. 在Linux下, 可以执行这样的命令来编译:

```shell
 c++ -O3 -Wall -shared -std=c++11 -fPIC $(python3 -m pybind11 --includes) example.cpp -o example$(python3-config --extension-suffix)
```

2. 我们也可以用setup.py来编译(在Windows下, 需要Visual Studio或mingw等编译工具; 在Linux或是Mac下, 需要gcc或clang等编译工具)

```python
from setuptools import setup, Extension
import pybind11

functions_module = Extension(
    name='example',
    sources=['example.cpp'],
    include_dirs=[pybind11.get_include()],
)

setup(ext_modules=[functions_module])
```

然后运行下面的命令, 就可以编译了

```shell
python setup.py build_ext --inplace
```

在python中进行调用

```shell
python -c "import example; print(example.add_func(200, 33))"
```

#### 在pybind11中指定函数参数

通过简单的代码修改，就可以通知Python参数名称

```c++
m.def("add", &add, "A function which adds two numbers",
      py::arg("i"), py::arg("j"));
```

也可以指定默认参数

```c++
int add(int i = 1, int j = 2) {
    return i + j;
}
```

在`PYBIND11_MODULE`中指定默认参数

```c++
m.def("add", &add, "A function which adds two numbers",
      py::arg("i") = 1, py::arg("j") = 2);
```

#### 为Python方法添加变量

```c++
PYBIND11_MODULE(example, m) {
    m.attr("the_answer") = 23333;
    py::object world = py::cast("World");
    m.attr("what") = world;
}
```

对于字符串, 需要用`py::cast`将其转化为Python对象.

然后在Python中, 可以访问`the_answer`和`what`对象

```python
import example
>>>example.the_answer
42
>>>example.what
'World'
```



#### 在cpp文件中调用python方法

因为python万物皆为对象, 因此我们可以用`py::object` 来保存Python中的变量/方法/模块等.

```c++
py::object os = py::module_::import("os");
py::object makedirs = os.attr("makedirs");
makedirs("/tmp/path/to/somewhere");
```

这就相当于在Python里执行了

```python
import os
makedirs = os.makedirs
makedirs("/tmp/path/to/somewhere")
```



#### 用pybind11使用python list

我们可以直接传入python的list

```c++
void print_list(py::list my_list) {
   for (auto item : my_list)
       py::print(item);
}

PYBIND11_MODULE(example, m) {
    m.def("print_list", &print_list, "function to print list", py::arg("my_list"));
}
```

在Python里跑一下这个程序, 

```python
>>>import example
>>>result = example.print_list([2, 23, 233])
2 
23 
233
>>>print(result)

```

这个函数也可以用`std::vector<int>`作为参数. 为什么可以这样做呢? pybind11可以自动将python list对象, 复制构造为`std::vector<int>`. 在返回的时候, 又自动地把`std::vector`转化为Python中的list. 代码如下:

```c++
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
std::vector<int> print_list2(std::vector<int> & my_list) {
    auto x = std::vector<int>();
    for (auto item : my_list){
        x.push_back(item + 233);
    }
    return x;
}

PYBIND11_MODULE(example, m) {
    m.def("print_list2", &print_list2, "help message", py::args("my_list"));
}
```



#### 用pybind11使用numpy

因为numpy比较好用, 所以如果能够把numpy数组作为参数传给pybind11, 那就非常香了. 代码如下(一大段)

```c++
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>

py::array_t<double> add_arrays(py::array_t<double> input1, py::array_t<double> input2) {
    py::buffer_info buf1 = input1.request(), buf2 = input2.request();

    if (buf1.ndim != 1 || buf2.ndim != 1)
        throw std::runtime_error("Number of dimensions must be one");

    if (buf1.size != buf2.size)
        throw std::runtime_error("Input shapes must match");

    /* No pointer is passed, so NumPy will allocate the buffer */
    auto result = py::array_t<double>(buf1.size);

    py::buffer_info buf3 = result.request();

    double *ptr1 = (double *) buf1.ptr,
           *ptr2 = (double *) buf2.ptr,
           *ptr3 = (double *) buf3.ptr;

    for (size_t idx = 0; idx < buf1.shape[0]; idx++)
        ptr3[idx] = ptr1[idx] + ptr2[idx];

    return result;
}

m.def("add_arrays", &add_arrays, "Add two NumPy arrays");
```

先把numpy的指针拿出来, 然后在指针上进行操作.

我们在Python里测试如下:

```python
>>>import example
>>>import numpy as np
>>>x = np.ones(3)
>>>y = np.ones(3)
>>>z = example.add_arrays(x, y)
>>>print(type(z))
<class 'numpy.ndarray'>
>>>print(z)
array([2., 2., 2.])
```



#### 总结

pybind11在C++下使用, 可以为Python程序提供C++接口. 同时, pybind11也支持传入python list, numpy等对象.

更多文档可以参考pybind11官方文档 https://pybind11.readthedocs.io/en/stable/

### 其他使用python调用C++的方式

1. CPython会自带一个Python.h, 我们可以在C/C++中引入这个头文件, 然后编译生成动态链接库. 但是, 直接调用Python.h写起来有一点点麻烦.
2. boost是一个C++库, 对Python.h做了封装, 但整个boost库比较庞大, 而且相关的文档不太友好.
3. swig(Simplified Wrapper and Interface Generator), 用特定的语法声明C/C++函数/变量. (之前tensorlfow用的就是这个, 但现在改成pybind11了)
4. a
5. etc

### 什么时候应该加速呢

用Python开发比较简洁, 用C++开发写起来有些麻烦. 

在写python时, 我们可以通过Profile等耗时分析工具, 找出比较用时的代码块, 对这一块用C++进行优化. 没必要优化所有的部分. 

### 总结:

Cython或是pybind11只做三件事: 加速, 加速, 还是加速. 在需要大量计算, 比较耗时的地方, 我们可以用C/C++来实现, 这样有助于提升整个Python程序的执行速度. 

加速python还有一些其他的方法, 比如用numpy的向量化操作代替for循环, 使用jit即时编译等.


## xmake简介

### 安装xmake

安装之前检查：

1. xmake的很多功能需要git，因此需要安装好[git](http://git-scm.com/)
2. 安装好任意C/C++编译器。推荐windows上安装Visual Studio或者mingw（需要设置好环境变量），macos安装XCode，linux安装gcc

[https://xmake.io/#/?id=installation](https://xmake.io/#/?id=installation)

建议使用powershell/bash安装，这样可以同时安装xmake的自动补全功能。

> Windows上使用powershell安装时，可能会遇到权限问题，可通过设置权限解决：
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### 快速入门

xmake是一个基于lua语言的构建系统。xmake使用工程根目录的xmake.lua文件来描述工程。一个最简单的hello world程序：
```shell
xmake create hello
cd hello
xmake
# xmake config -p mingw, if using mingw on windows
xmake run
```
此时应该已经可以看到`hello world!`的输出。

接着运行
```shell
xmake clean
```
即可删除构建产生的二进制文件。

### xmake.lua结构探秘

使用任意文本编辑器打开xmake.lua文件。除去注释以外（lua中一行`--`之后的部分视为注释）部分如下
```lua
 add_rules("mode.debug", "mode.release")
 
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
```
解释：第一行内容`add_rules(...)`为程序添加了默认的debug符号以及release优化选项。加入这一行之后，可以用`xmake config -m debug/release`来切换debug和release编译模式（与VS不同，xmake默认的编译模式是release）。如果不加，则默认不会加入任何额外的编译选项，把自定义编译选项的任务交给用户。运行`xmake -v`可以看到实际执行的命令，这样就可以看出mode.release增加的选项了。

> 修改xmake.lua之后，建议运行一次`xmake f -c`，以清理上次构建的缓存。

`target("hello")`表示定义一个名为`hello`的target，它输出的文件名默认为`hello<.ext>`，`<.ext>`扩展名与target的类型（kind）有关。对于binary类型，扩展名在UNIX系上没有，在windows上为`.exe`。由于binary类型是默认的类型，其实这里的`set_kind("binary")`可以不写。

`add_files("src/*.cpp")`表示将src目录下的所有cpp文件加入target中。由于头文件的检索由编译器自动完成，不需要对头文件进行编译，所以头文件（.h和.hpp）直接在代码中引用即可，不需要加入target。如果要增加额外的头文件搜索路径，需要在target下增加语句
```lua
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
+  add_includedirs("<incdir>")
```

## 使用xmake编译可执行程序

### target的进一步设定

对C++的项目，C++的语言版本是很重要的参数。最好这个语言版本在所有的二进制文件中都保持一致。建议的设置方法是
```lua
+set_languages("c11", "c++17")
 add_rules("mode.debug", "mode.release")
 
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
```

如果添加额外的编译期预定义，只需要增加一行
```lua
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
+  add_defines("TEST=1")
```

这是一个最简单的工程，不需要引用crt和c++ runtime之外的库文件，因此这样写就足够了。如果需要加入系统库文件，例如pthread，可以增加语句
```lua
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
+  add_syslinks("pthread")
```

### 使用第三方库

如果需要加入从某些地方自己下载的库，可以写
```lua
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
+  add_linkdirs("<linkdir>")
+  add_links("<link>")
```
但如果你使用了xmake，要使用第三方库，你通常无需自己下载或编译，因为xmake自带的包管理器可以帮你做这些事情。以依赖glfw和imgui的一个gui程序为例，只需要在xmake.lua中这样写
```lua
 set_languages("c11", "c++17")
 add_rules("mode.debug", "mode.release")

+add_requires("imgui", {configs={glfw_opengl3=true}})
 
 target("hello")
   set_kind("binary")
   add_files("src/*.cpp")
+  add_packages("imgui")
```
main.cpp使用imgui的[示例程序](https://github.com/ocornut/imgui/blob/master/examples/example_glfw_opengl3/main.cpp)

> 由于imgui的一项修改没有同步到示例中，该示例可能会无法编译通过，只需要在最开始加上一行`#include "imgui_impl_opengl3_loader.h"`。

使用`xmake f -c && xmake`进行编译，使用`xmake run -w . hello`运行即可看到imgui窗口。

对于其他第三方库，操作是类似的。你可以在包管理器[xrepo的主页](https://xrepo.xmake.io/#/)搜索你想要的第三方库。如果xrepo没有收录，你可以使用其他的第三方库源（vcpkg，conan，apt，homebrew，等等）集成到xmake，或者向xrepo[贡献新的package](https://xmake.io/#/package/remote_package)。

### 使用function

当需要构建大量target的时候，可能会遇到很多重复的代码片段，给维护带来困难。面对这种情况，可以使用function来简化xmake.lua的编写。举例：

```lua
set_project("numcomp") -- set project name
set_xmakever("2.6.1")  -- set minimal xmake version

add_rules("mode.debug", "mode.release")
add_requires("eigen 3.x") -- use Eigen3 of any minor version
add_requires("openmp", "cuda", {system = true})

function numcomp_add_cpu_target(name)
  target(name)
    set_kind("binary")
    add_files(format("src/%s.cpp", name))
    add_packages("eigen", "openmp")
    add_defines("EIGEN_HAS_OPENMP")
  target_end() -- explicitly close the target description
end

function numcomp_add_gpu_target(name)
  target(name)
    set_kind("binary")
    add_files(format("src/%s.cu", name))
    add_packages("eigen", "cuda")
  target_end()
end

numcomp_add_cpu_target("cpu01") -- src/cpu01.cpp
numcomp_add_cpu_target("cpu02") -- src/cpu02.cpp
numcomp_add_gpu_target("gpu01") -- src/gpu01.cu
```

### 使用多级目录结构

有时候为了整个工程的清晰起见，将每个具体的target定义放在子文件夹下，而根目录的xmake.lua仅用作入口。xmake提供了`includes`语句来实现这一构造。目录结构如下图
```
root
|- xmake.lua
|- lib1
   |- xmake.lua
   |- lib1.cpp
|- lib2
   |- xmake.lua
   |- lib2.cpp
```

这样根目录下的xmake.lua只要写
```lua
add_rules("mode.debug", "mode.release")

includes("lib1")
includes("lib2")
```

### 在IDE中使用xmake

xmake可以生成compile_commands.json、CMakeLists.txt、Visual Studio Solution等多种格式的文件供IDE使用。以Visual Studio Code为例，要配置intellisense，只需要运行
```
xmake project -k compile_commands
```
然后在Ctrl+Shift+P，选择`C/C++: Edit Configurations (UI)`，在Advanced Settings中Compile commands一栏填入
```
${workspaceFolder}/compile_commands.json
```
即可。VSCode的XMake插件提供了运行/调试工程的GUI界面，以及compile_commands.json的生成（在xmake.lua发生变化时自动重新生成，其余时候使用Ctrl+Shift+P选择`XMake: Update Intellisense`手动生成）。

> 使用VSCode的XMake插件时，默认的生成目录位于`${workspaceFolder}/.vscode/compile_commands.json`，在上方C/C++插件的设置需要调整一下。

对Visual Studio，运行
```
xmake project -k vsxmake
```
生成IDE文件，打开即可。对CLion等其他IDE（当然VS也是可以的），运行
```
xmake project -k cmake
```
然后使用IDE内置的CMake支持（如果有的话）即可提供Intellisense。在工程发生变化时，需要手动运行一下此命令，重新生成IDE/cmake文件。

### 发布程序

运行`xmake install -o dist`即可将编译得到的二进制与可能需要的动态库文件输出到dist文件夹中。通常情况下，将dist文件夹打包发布即可。

## 创建自己的C/C++库

### 创建仅头文件的库

仅头文件的库最容易声明，典型的库目录结构如下
```
root
|- xmake.lua
|- include
   |- mylib
      |- mylib.hpp
|- examples
   |- xmake.lua
   |- myexample.cpp
```

根目录下的xmake.lua
```lua
set_project("mylib")
set_xmakever("2.6.1")
add_rules("mode.debug", "mode.release")

target("mylib")
  set_kind("headeronly") -- static/shared for static/shared library, $(kind) for either static or shared
  add_headerfiles("include/(mylib/mylib.hpp)") -- parentheses for keeping the relative path
  add_includedirs("include", {public = true})
  --add_rules("utils.install.cmake_importfiles") -- export .cmake files for any other cmake projects
target_end()

includes("examples")
```

examples/xmake.lua
```lua
target("myexample")
  set_kind("binary")
  add_deps("mylib") -- specify dependency on other target
  add_files("myexample.cpp")
  on_install(function (target) end) -- empty function body; prevent example from being installed
```

运行`xmake && xmake install -o dist`，库中的头文件就被顺利安装到`dist/include/mylib/mylib.hpp`了。把`dist`文件夹打包即可发布。

### *创建静态/动态链接库

静态链接库就是大量编译中间文件打包的集合，对其中的函数能否运行没有任何保证，链接到静态链接库相当于与静态链接库的源文件一起编译链接。而动态链接库是一系列链接后的函数符号的集体，这些函数都是可以直接运行的，其中没有未定义的符号，链接到动态链接库仅仅链接到这些符号的一个定义，而不会链接到函数的实现。通常链接到动态库的二进制文件体积会小得多，但代价是运行时必须调整好环境变量让OS能够找到动态链接库，发布的时候必须与动态链接库一同发布。动态链接库在更新时如果没有改变接口，而仅仅改变了实现，则所有依赖于它的二进制文件都不需要重新编译。但对静态链接库，任何改动都会导致所有依赖于它的二进制文件都需要重新编译。

一个高质量的C/C++库应该能够做到既可编译为静态库，也可编译为动态库。目录结构如下
```
root
|- xmake.lua
|- include
   |- mylib
      |- mylib.h
|- src
   |- mylib.cpp
   |- myclass.cpp
   |- myclass.h
|- examples
   |- xmake.lua
   |- myexample.cpp
```
根目录下的xmake.lua
```lua
set_project("mylib")
set_xmakever("2.6.1")
add_rules("mode.debug", "mode.release")

target("mylib")
  set_kind("$(kind)")
  add_files("src/mylib.cpp", "src/myclass.cpp") -- wildcard is ok: "src/*.cpp"
  add_headerfiles("include/(mylib/mylib.h)")
  add_includedirs("include", {public = true})
  --add_rules("utils.install.cmake_importfiles")
target_end()

includes("examples")
```
在编译时，通过kind控制编译出的库为静态/动态：
```shell
xmake f -m release -k static # static library
xmake
xmake install -o dist
```
或者
```shell
xmake f -m release -k shared # shared library
xmake
xmake install -o dist
```

如果想要让你的库广为人知，可以为你的库写一个package文件，并通过pull request的形式提交到github的xmake-repo。待合并后，你的库就可以被其他人以`add_requires("<your library>")`的形式直接引用了！

## FAQ

1. xmake与cmake的对比？

    相比于cmake，xmake增加了很多额外的功能，同时使用贴近人类思考方式的lua语法，免去了cmake繁重的学习负担。xmake也存在它的问题，xmake还年轻，对很多特殊项目的处理缺少现成的example，同时功能也在不断的进化中，难免会有一些bug（但其实，cmake发展了20年，bug还是不少）。从我的个人经验来看，cmake社区我提一个问题后，3个月后才有人回复，回复的内容是“I have the same problem.”，而xmake的issue能够在一两天内得到回复。同时，xmake的源码架构清晰，易于调试，很多时候完全可以自己定位问题，并且反馈到上游；而cmake难以调试，在更改其源码后往往需要重新编译运行，对于开发者不太友好。在使用xmake遇到问题时，解决起来是比cmake容易太多的。但以下情况建议还是使用cmake：

    1. 组内已有基于cmake的项目，有人维护的情况下没有必要切换。
    2. 经过多年踩坑已经非常熟悉cmake及其生态，并且对xmake提供的新功能不感兴趣，建议继续使用cmake。
    3. 所用的第三方库使用了cmake的特殊语法（例如，提供了一些自定义的cmake macro），不想用xmake重新实现，建议使用cmake。
    4. 我觉得cmake设计得很好！emmm

2. xmake下载第三方库速度缓慢，怎么办？

    大部分第三方库从github.com下载，而github由于众所周知的原因在国内访问比较缓慢。xmake提供了设置镜像的方法，见[mirror-agent](https://xmake.io/#/package/remote_package?id=mirror-agent)。使用方法：
    1. 在`<home>/.xmake`或者windows上的`<home>/AppData/Local/.xmake`文件夹创建文件pac.lua，内容为
    ```
    function mirror(url)
        return url:gsub("github.com", "hub.fastgit.org")
    end
    ```
    2. 运行`xmake g --proxy_pac=pac.lua`。That's all!

3. 在xmake.lua中使用`print`，结果print会输出多次，为什么？

    xmake.lua其实是一个描述文件，只是借用了lua的语法。在xmake.lua中非脚本域无法使用xmake提供的lua扩展模块，并且直接写的lua语句都会被执行多次。xmake在设计上采用了描述域与脚本域分离的设计，只有在脚本域中才能保证lua语句的单次执行和使用xmake提供的扩展模块。脚本域的示例：
    ```lua
    target("hello")
        set_kind("binary")
        add_files("src/*.cpp")
        on_load(function (target)
            -- Here is script scope!
            target:add("defines", "TESTDEF")
            print("what i want")
        end)
    ```
    这样的设计，既保证了xmake.lua对简单项目的简洁性，也保证了对复杂项目的可自定义扩展性。因此，如果需要进行复杂的逻辑运算和输出，建议都放在脚本域进行。

    p.s. 如果只是想用print来调试的话，只看最后一次输出就好。

4. 我在使用xmake过程中遇到问题/不清楚某项功能如何实现，怎么办？

    1. 运行`xmake -vD`，很多时候问题出在哪里通过log就可以判断。
    2. 利用[文档](https://xmake.io/#/)的搜索功能。
    3. 使用github的[讨论区](https://github.com/xmake-io/xmake/discussions)进行提问。
    4. xmake的底层使用C编写，上层逻辑使用lua编写。你可以在xmake安装目录下的`xmake`文件夹中找到这些lua script，使用print大法进行调试。即时修改，即时生效。你对问题的定位可能会大大加快问题解决的速度。


## 附录1：lua语言简介

参考：[lua官方文档](https://www.lua.org/manual/5.4/manual.html)

### 变量与表达式

lua是动态解释型语言，没有静态类型约束。

常用的lua变量有nil、boolean、数值、字符串、table、function等。定义局部变量：
```lua
local a = 1
local b = true
```
运算表达式和C相同。逻辑表达式：
```lua
local c = a and b
local d = a or b
```
关系表达式：
```lua
local c = (a > b)
local d = (a ~= b) -- a != b in C++
```

### table对象

定义一个table对象
```lua
local t = {1, 2, 3, 4}
```
取值
```lua
local a = t[1] -- indices start from 1, NOT 0!
```
求长度
```lua
local len_t = #t
```
增删改查
```lua
table.insert(t, 5)
table.remove(t, 3)
t[3] = 6
local res = table.contains(t, 3) -- not lua standard, provided by xmake
```
排序
```lua
table.sort(t)
```
table既是数组，也是hashmap。使用自定义key的table对象：
```lua
local mymodule = {name = "a module", version = "1.0"}
```
取值/赋值
```lua
local n = mymodule.name
local n = mymodule["name"] -- same as above
mymodule.keyword = "test"
```

### 顺序结构、分支结构与循环结构

lua语句默认顺序执行。分支判断的关键词为`if`：
```lua
if condition then
  <do something>
else
  <do something other>
end
```
对于简单的语句可以用三目运算：
```lua
local c = condition and a or b
```
常用的循环语句关键词为`for`和`while`：
```lua
local list = {1, 2, 3, 4, 5}
for _, item in ipairs(list) do
  print(item)
end
local a = 0
while a < 5 do
  print(a)
  a = a + 1
end
```

## 附录2：C/C++构建系统简史

最开始，只有编译器的概念，没有构建系统的概念。随着工程的扩大，编译选项的增加，一部分人开始使用shell等自动化工具来管理编译流程，这就是构建系统的雏形。最早在C/C++中得到广泛应用的构建系统是GNU Make，其标志性构建文件为Makefile，由于好念下面就叫它Makefile。Makefile的语法贴近bash（which means 和正常人类习惯相去甚远），使用起来和bash也配合得很好，在UNIX系的系统上广为流传。然而，Makefile的功能性实在太差，使得Makefile中常常需要用bash执行命令甚至需要调用awk、sed等程序来完成一些功能，这使得Makefile性能较差、常常无法跨平台工作。Visual Studio中附带了一个叫NMake的工具，这是GNU Make在Windows上的仿造品，但使用者寥寥。

Makefile的使用方法很简单：
```shell
# setup environment variables in advance
make <target>
```
通常只要执行`make`就行了。有的项目会加一些`check`、`install`等额外的target，并用目录下的README或者INSTALL对此进行说明。

Makefile对较大的工程力不从心，更糟糕的是，即使在UNIX平台上，各个编译器的标准库也不完全一致。这使得Makefile连同平台的跨编译器行为都无法保证。之后便有了GNU autoconf和GNU automake，它们的使用方法很典型，并且随着一些祖传项目一直流传到今天：
```
./configure --prefix=/usr/local
make
make install
```
autoconf也绑定bash，执行过程非常复杂，并且其多进程模型导致它在windows上执行极为缓慢，所以autoconf实际上是不能称为跨平台构建工具的。它流行只是因为在恰当的时机出现在了恰当的位置解决了跨编译器行为的问题。然而，autoconf极为复杂的语法非常劝退，现在开始的新项目应该不会有人再去尝试autoconf了。

Windows从出生起就被GNU的这套工具链排斥在外。不过微软不在乎，微软有自己的MSVC，以及与之绑定的VC++、Visual Studio等IDE。从一开始的.dsw文件到后来的MSBuild都是“面向IDE”的构建工具，压根没准备让人手写，你只需要在VS里面拖动、点击、拖动、点击就行了。然而这套逻辑在工程量大的时候是很费手的。对工程文件的阅读也是一个灾难——别人创建的工程文件换一个人来几乎不可读，他无法分辨前一个人到底改了哪些地方。雪上加霜的是，微软这套工具链还不保证后向兼容。也就是说，一套构建系统如果不常常在IDE里升级，那多半过一段时间就没法用了。

C/C++社区苦分裂现状久矣，于是CMake站了出来，立志统一Windows和UNIX。他也确实做到了，和autoconf类似，CMake也是一个生成构建文件的meta-build system，本身不能构建。但CMake抛弃了对bash的依赖，抛弃了autoconf的海量进程设计，自创一套DSL，解决了工程文件无法跨平台的问题。同样一个工程，用Makefile需要写5000行，换成CMake可能只需要1000行。CMake的使用一般是这样
```
mkdir build
cd build
cmake ..
make
make install
```
或者在windows上这样
```
mkdir build
cd build
cmake ..
msbuild <project>.sln # 或者用Visual Studio打开
```
目前大量C/C++项目都已经或者在考虑使用CMake。但是，CMake也有它的弊端：首先，他设计的DSL是shit。难学、难用、难维护。其次，CMake抛弃多进程同时又没有很好的多线程管理，导致CMake运行起来缓慢，而构建系统后端使用Makefile和MSBuild导致构建也比较缓慢。（p.s. MSBuild的多线程构建其实优化的不错，但遇到自定义的编译规则，例如CUDA编译，MSBuild立马歇菜）Ninja的出现部分缓解了这个问题。再次，CMake历史上存在很多失败的设计（全局变量，一些特殊变量的引入和含义，等等），这些设计会使得混合不同的cmake项目时，尤其是比较老的CMake项目时，出现冲突（全局变量！）。除此之外，还有巨多没有写在文档里的神坑。最后，CMake缺少作为一个现代化语言构建系统的许多要素：包管理、依赖锁定（reproducible build）、虚拟环境、对交叉编译的原生支持等。vcpkg和conan解决了CMake的一部分痛点，但CMake问题已经太多，即使再改良，也难以和npm/cargo这样真正现代化的构建工具相比拟了。

由于CMake实在无法让大家满意，继CMake之后，出现了大量的其他C/C++构建工具，比较出名的有meson、scons、gyp/gn、xmake、bazel、bjam等等。大部分解决了cmake的一部分问题，xmake解决了上面比较多的问题：易用性，可读性，跨平台跨交叉编译链，速度，可重复性，包管理，虚拟环境，功能可扩展性。使用cmake需要写1000行的构建系统，换成xmake大概只需要200行。虽说这里只是以xmake为例介绍C/C++构建系统的一些要素，这些概念放在其他构建系统上大多也是通用的。

## 附录3：编译、链接与装载

从C/C++的源代码，到最终的执行结果，需要几个步骤：

- 编译——将源代码进行处理，翻译成汇编代码，再将汇编代码转译成二进制文件。这一步最常见的是
  > main.cpp(12): fatal error: ...
- 链接——把需要用到的非动态链接库函数中的二进制文件集合在一起。这一步最常见的是
  > main.o: undefined reference to `pthread_create' ...
- 运行——把每一个函数调用解析到对应的动态链接库，从main函数开始执行。这一步最常见的是
  > ./main: error while loading shared libraries: libfoo.so.1: cannot open shared object file: No such file or directory

当然，说的是手动编译链接的情况。这期间常用的指令有：

1. 编译

  - 指定仅编译，不尝试链接
  ```
  gcc -c ...
  cl.exe /c ...
  ```

  - 指定头文件的查找位置`<incdir>`。`#include "subdir/file"`这样的语句会从incdir往下查找。
  ```
  gcc -I<incdir> ...
  cl.exe /I<incdir> ...
  ```

  - 指定额外的宏定义`<def>`，值为`<value>`
  ```
  gcc -D<def>=<value> ...
  cl.exe /D<def>=<value> ...
  ```

  - 指定调试符号/优化级别/警告级别
  ```
  gcc -g -O2 -Wall ...
  cl.exe /Zi /Od /W3 ...
  ```

2. 链接

  - 指定链接目录
  ```
  ld -Lext/libs ...
  link.exe /LIBPATH:ext/libs ...
  ```

  - 指定链接（linux上需要注意链接顺序！）
  ```
  ld -lmylib ...
  link.exe mylib.lib ...
  ```

3. 运行

  - 设置动态链接库的搜索路径
  ```
  export LD_LIBRARY_PATH="<libpath>:$LD_LIBRARY_PATH"
  $env:PATH="<libpath>;$env:PATH"
  ```