#---导入目标库---the libraries you need to import
import datetime
from flask import Flask, redirect,render_template,request, url_for
from flask_login import LoginManager, current_user,login_user,UserMixin,login_required, logout_user
import sqlite3
import hashlib
import yaml
import os

#---基础配置---base settings---

#特别说明，本程序并不针对多用户服务开发，仅支持单用户管理
#Explain:this program is not developed for multipe users.Only support one user.
class User(UserMixin):
    def __init__(self,user_id):
        self.id = user_id

app = Flask(__name__)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)
app.secret_key =  str(os.environ.get('FLASK_SECRET_KEY')) #密钥(secret key)
app.config['PORT'] = int(config['port']) #服务端口(server port)
app.config['DATABASE'] = str(config['database']) #数据库名和位置(database name and location)
app.config['ROOT'] = str(config['root']) #分享文件根目录(the files root path which you need to share.Usually the NAS root path)
app.config['READ'] = int(config['read']) #SHA计算时每次读取的文件大小，默认8KB(the sha256 calculator read file size each time.Default 8KB)
app.config['PASSWORD'] = str(config['password']) #用户密码(User's password)

#---基本函数---base functions---

@login_manager.user_loader
def load_user(user_id):
    return User(1)

def opreat_db():#数据库操作基本函数(database opreation function)
    con = sqlite3.connect(app.config['DATABASE'])
    con.row_factory = sqlite3.Row
    return con

def sha_calculate(file_path):#sha256计算器(sha256 calculator)
    if not os.path.isfile(file_path):
        print("文件不存在。")
        return None
    sha512_256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        while chunk := f.read(app.config['READ']*8):
            sha512_256.update(chunk)

    return sha512_256.hexdigest()

#---路由设置---route settings---

@app.route('/login', methods=['GET', 'POST'])#登录(login)
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        password = request.form['pwd']
        if password == app.config['PASSWORD']:
            user = User(1)
            login_user(user)
            return redirect(url_for('dashboard'))
        else:
            msg = "密码错误！"#Error message!Password is not correct
            return render_template('result.html',msg=msg)
    return render_template('login.html')

@app.route('/logout')#登出(logout)
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route("/dashboard")#仪表盘逻辑(dashboard logic)
@login_required
def dashboard():
    con = opreat_db()
    cur = con.cursor()
    cur.execute("SELECT * FROM shares")
    rows = cur.fetchall()
    total = con.execute('SELECT COUNT(*) as count FROM shares').fetchone()['count']
    con.close()
    return render_template("dashboard.html",rows = rows,total = total)
@login_manager.unauthorized_handler
def unauthorized():
    return '您没有权限访问！'

@app.route("/create")#单击创建分享时的新建分享页面(page which you click ths create button)
@login_required
def create():
    return render_template('create.html')
@login_manager.unauthorized_handler
def unauthorized():
    return '您没有权限访问！'

@app.route("/<sha256>/delet",methods=['GET'])
@login_required
def Delet(sha256):
    db = opreat_db()
    share = db.execute('SELECT * FROM shares WHERE sha256 = ?', (sha256,)).fetchone()
    if not share:
        db.close()
        msg = '共享不存在或已被删除'
        return render_template('result.html',msg=msg)
    db.execute('DELETE FROM shares WHERE sha256 = ?', (sha256,))
    db.commit()
    db.close()
    msg = '共享删除成功'
    return render_template('result.html',msg=msg)
@login_manager.unauthorized_handler
def unauthorized():
    return '您没有权限访问！'
@app.route('/result',methods = ['GET', 'POST'])#接受创建表单并返回结果(receive ths request and return results)
@login_required
def Add():
    msg = '已成功创建分享'#Success message!
    path = request.form['path']
    if not os.path.exists(path):
        msg = '指定的文件路径不存在！'#Error message!the path is not existed
        return render_template('result.html',msg=msg)
    sha256 = sha_calculate(path)
    name = os.path.basename(path)
    expire_days = int(request.form['days'])
    expire_time = (datetime.datetime.now() + datetime.timedelta(days=expire_days)).strftime('%Y-%m-%d %H:%M:%S')
    Max = request.form['max']
    try:
        db = opreat_db()
        db.execute('''
                INSERT INTO shares 
                (sha256, file_path, file_name, expire_time, max_downloads)
                VALUES (?, ?, ?, ?, ?)
            ''', (sha256, path, name, expire_time, Max))
        db.commit()
        db.close()
        return render_template('result.html',msg = msg)
    except sqlite3.IntegrityError:
        msg = '已共享该文件！'#Error Message!the file is repeated
        return render_template('result.html',msg=msg)
    except Exception as e:#Error Message!database error
        msg = '数据库错误！抛出异常：<br>'+str(e)
        return render_template('result.html',msg=msg)
@login_manager.unauthorized_handler
def unauthorized():
    return '您没有权限访问！'

if __name__ == "__main__":
    app.run(port=app.config['PORT'],debug=False)