# NASDirectLinkShareTool(NDL)

欢迎访问本项目，如你所见，这是一个轻量级的微服务，在你想向你的好友或家人分享NAS文件时，不需要再给他们下载各种客户端，不需要留下你的NAS用户名密码，直接就可以获得一个直链，找一个浏览器就可以下载

this tool made with Python Flask,it's soft,fast,convenient and useful.You can use it if you want to share file which on your NAS.You wouldn't to talk your NAS password and username to others.Even you wouldn't need to download an app on a new device.Just copy the link and go to the browser.Download!

---
## 项目结构
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
## 配置服务 
### 方法一 自动配置
如果您是在Linux环境下配置的则可以直接运行start.sh即可配置，但您仍需执行方法二的步骤
### 方法二 手动配置
步骤一
请您按实际情况配置config.yaml文件

步骤二
检查python库是否有相关依赖，依赖库:
```
PyYaml flask flask-login sqlite3 
```


步骤三 

---
本项目分为两个py程序，一个名为control.py是网页客户端，您可以运行这两个程序，访问
```
http(s)://<你的域名/IP地址>:5001/login
```
是项目的入口，登录就可以使用了
