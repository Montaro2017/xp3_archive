# XP3文件提取器
## 使用
```
xp3_archive.exe extract -i xp3文件 -o 输出目录
eg: xp3_archive.exe extract -i D:\data.xp3 -o data
-h, --help            Print this usage information.
-p, --[no-]print      是否打印文件名 默认false
-i, --input=<file>    xp3或exe文件路径 可以使用相对路径
-o, --output=<dir>    输出目录 可空 可以使用相对路径 默认使用xp3文件同名目录如D:\data
```

## 下载
[下载地址](https://gitee.com/Montaro2017/xp3_archive/releases)
## 编译
由于目前dart暂不支持交叉编译，只能根据当前平台编译，因此只提供windows版可执行文件，其他平台请自行编译。
### Windows
直接执行项目下的 **compile.bat** 

或者执行
```
dart compile exe bin/xp3_archive.dart -o ./build/xp3_archive.exe
```

### Linux / macOS
```
dart compile exe bin/xp3_archive.dart -o ./build/xp3_archive
```
