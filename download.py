#---导入目标库---the libraries you need to import
from flask import Flask, send_from_directory, abort
import sqlite3
import yaml
from datetime import datetime
import os

#---基础配置---base settings---
app = Flask(__name__)

with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)
app.config['DATABASE'] = str(config['database'])
app.config['ROOT'] = str(config['root'])

#---基本函数---base functions---
def get_file_path(sha256):
    """查询数据库，返回文件路径及限制信息"""
    conn = sqlite3.connect(app.config['DATABASE'])
    cursor = conn.cursor()
    cursor.execute("""
        SELECT file_path, expire_time, max_downloads, current_downloads 
        FROM shares WHERE sha256 = ?
    """, (sha256,))
    result = cursor.fetchone()
    conn.close()
    if not result:
        return None  # 哈希不存在
    file_path, expire_time, max_downloads, current_downloads = result
    # 检查过期时间
    if expire_time and datetime.now() > datetime.fromisoformat(expire_time):
        return "expired"
    # 检查下载次数
    if max_downloads and current_downloads >= max_downloads:
        return "max_downloads"
    # 更新下载次数
    conn = sqlite3.connect(app.config['DATABASE'])
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE shares SET current_downloads = current_downloads + 1 
        WHERE sha256 = ?
    """, (sha256,))
    conn.commit()
    conn.close()
    return file_path

#---路由设置---route settings---
@app.route('/<sha256>')
def download_file(sha256):
    file_path = get_file_path(sha256)
    if file_path is None:
        abort(404, description="文件不存在或已取消共享")
    if file_path in ["expired", "max_downloads"]:
        abort(403, description="文件已过期或超过最大下载次数")
    if not file_path.startswith(app.config['ROOT']):
        abort(403, description="非法文件路径")
    dir_path = os.path.dirname(file_path)
    file_name = os.path.basename(file_path)
    return send_from_directory(dir_path, file_name, as_attachment=True)

if __name__ == '__main__':
    app.run(port=5000, debug=False)
