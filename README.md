# NASDirectLinkShareTool(NDL)

欢迎访问本项目，如你所见，这是一个轻量级的微服务，在你想向你的好友或家人分享NAS文件时，不需要再给他们下载各种客户端，不需要留下你的NAS用户名密码，直接就可以获得一个直链，找一个浏览器就可以下载

this tool made with Python Flask,it's soft,fast,convenient and useful.You can use it if you want to share file which on your NAS.You wouldn't to talk your NAS password and username to others.Even you wouldn't need to download an app on a new device.Just copy the link and go to the browser.Download!

---
## 项目结构 Project Structure
```
-|
 |-control.py  ------------------ 网页服务端(Web Server)
 |-download.py ------------------ 下载服务端(Download Server)
 |-config.yaml ------------------ 配置文件(Config file)
 |-start.sh    ------------------ Linux自动执行脚本(Linux auto-run script)
 |-templates
   |-create.html ---------------- 创建新共享页面(Page that create new share link)  
   |-dashboard.html ------------- 仪表盘(Dashboard page)
   |-login.html ----------------- 登录页面(Login page)
   |-result.html ---------------- 操作结果反馈(Page that return the result)
```
---
## 配置服务 Configure the serve
### 方法一 自动配置 Method 1
如果您是在Linux环境下配置的则可以直接运行start.sh即可配置，但您仍需执行方法二的步骤三

If you run this program on Linux.You can use the start.sh to configure the program automatically.But you also need to follow the step3 on Method2
### 方法二 手动配置 Method 2 
#### 步骤一
请您按实际情况配置config.yaml文件

#### Step1 Please configure the config.yaml file according to the actual situation

#### 步骤二

检查python库是否有相关依赖，依赖库: Check the libaries which this program need:
```
PyYaml flask flask-login sqlite3 
```


#### 步骤三 出于安全考虑，并没有把网页交互内容和实际下载功能放在一起，而是进行隔离，因此你需要改动dashboard.html中的一行

#### Step3 To ensure the safty.I didn't develop the download function  in the same script.So,you need to change this place with your domains which can visit port 5000 or your IPv4:5000
```
109 <!--注意！请在此处填写您的下载地址！--><a href="<你的下载地址>/{{ row["sha256"] }}" 
```
请在对应位置填写指向5000端口的网址或者您的IP地址:5000

#### 步骤四
确保系统环境内存在环境变量FLASK_SECRET_KEY，您可以使用python或其他工具生成一个32位的16进制随机数列来充当密钥

#### Step4

Ensure the system environment has variable named FLASK_SECRET_KEY.You can use python or other tool to make a 32-bit hexadecimal random sequence as your secret key


---
本项目分为两个py程序，一个名为control.py是网页客户端，您可以运行这两个程序，访问
```
http(s)://<你的域名/IP地址>:5001/login
```
是项目的入口，登录就可以使用了
源代码中都标好了注释不明白的可以看作者的博客了解本项目

---
## 本项目使用Apache 2.0开源协议，请您遵守开源法则，若您要引用，请标注作者名字，欢迎您提出意见！
