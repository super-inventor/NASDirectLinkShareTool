#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装 $1"
        exit 1
    else
        print_info "找到命令: $1"
    fi
}

# 生成32位16进制随机数作为FLASK_SECRET_KEY
generate_secret_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    else
        # 如果没有openssl，使用/dev/urandom作为备选
        head -c 32 /dev/urandom | xxd -ps -c 32
    fi
}

# 设置FLASK_SECRET_KEY环境变量
setup_flask_secret() {
    if [ -z "$FLASK_SECRET_KEY" ]; then
        print_info "生成FLASK_SECRET_KEY环境变量..."
        SECRET_KEY=$(generate_secret_key)
        export FLASK_SECRET_KEY=$SECRET_KEY

        # 添加到当前shell环境
        echo "export FLASK_SECRET_KEY=$SECRET_KEY" >> ~/.bashrc
        echo "export FLASK_SECRET_KEY=$SECRET_KEY" >> ~/.profile

        print_success "FLASK_SECRET_KEY已设置并添加到shell配置文件"
        print_info "FLASK_SECRET_KEY: $SECRET_KEY"
        print_warning "请运行 'source ~/.bashrc' 或重新登录以使环境变量生效"
    else
        print_info "FLASK_SECRET_KEY环境变量已存在"
    fi
}

# 创建并激活Python虚拟环境
setup_virtualenv() {
    if [ ! -d "venv" ]; then
        print_info "创建Python虚拟环境..."
        python3 -m venv venv
        if [ $? -ne 0 ]; then
            print_error "创建虚拟环境失败"
            exit 1
        fi
        print_success "虚拟环境创建成功"
    else
        print_info "虚拟环境已存在"
    fi

    # 激活虚拟环境
    print_info "激活虚拟环境..."
    source venv/bin/activate

    # 检查是否成功激活
    if [[ "$VIRTUAL_ENV" != "" ]]; then
        print_success "虚拟环境已激活: $VIRTUAL_ENV"
    else
        print_error "虚拟环境激活失败"
        exit 1
    fi
}

# 在虚拟环境中安装Python依赖
install_dependencies() {
    print_info "在虚拟环境中安装Python依赖..."

    # 升级pip
    pip install --upgrade pip

    # 安装依赖（包括flask_login）
    pip install flask pyyaml flask_login

    if [ $? -eq 0 ]; then
        print_success "依赖安装成功"
    else
        print_error "依赖安装失败"
        exit 1
    fi
}

# 配置config.yaml
configure_app() {
    print_info "开始配置应用..."

    # 设置默认值
    PORT=5001
    DATABASE=""
    ROOT=""
    READ=8
    PASSWORD=""

    # 获取用户输入
    read -p "请输入服务端口 [默认: 5001]: " input_port
    if [ ! -z "$input_port" ]; then
        PORT=$input_port
    fi

    while [ -z "$DATABASE" ]; do
        read -p "请输入数据库文件路径 (必填): " DATABASE
        if [ -z "$DATABASE" ]; then
            print_error "数据库路径不能为空!"
        fi
    done

    while [ -z "$ROOT" ]; do
        read -p "请输入NAS根目录路径 (必填): " ROOT
        if [ -z "$ROOT" ]; then
            print_error "NAS根目录不能为空!"
        elif [ ! -d "$ROOT" ]; then
            print_warning "目录不存在，将尝试创建..."
            mkdir -p "$ROOT"
            if [ $? -ne 0 ]; then
                print_error "无法创建目录: $ROOT"
                ROOT=""
            else
                print_success "目录创建成功: $ROOT"
            fi
        fi
    done

    read -p "请输入读取速率 [默认: 8]: " input_read
    if [ ! -z "$input_read" ]; then
        READ=$input_read
    fi

    while [ -z "$PASSWORD" ]; do
        read -s -p "请输入密码 (必填): " PASSWORD
        echo
        if [ -z "$PASSWORD" ]; then
            print_error "密码不能为空!"
        fi
    done

    # 创建配置文件
    cat > config.yaml << EOL
port: $PORT
database: '$DATABASE'
root: '$ROOT'
read: $READ
password: '$PASSWORD'
EOL

    print_success "配置文件 config.yaml 创建成功!"
}

# 检查并创建SQLite数据库和表
setup_database() {
    if [ ! -f "$DATABASE" ]; then
        print_info "创建SQLite数据库: $DATABASE"
        sqlite3 "$DATABASE" ""
        if [ $? -eq 0 ]; then
            print_success "数据库创建成功"

            # 创建表
            print_info "创建数据库表..."
            sqlite3 "$DATABASE" "CREATE TABLE IF NOT EXISTS shares (
                sha256 TEXT PRIMARY KEY,
                file_path TEXT NOT NULL,
                file_name TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                expire_time DATETIME,
                max_downloads INTEGER,
                current_downloads INTEGER DEFAULT 0
            );"

            if [ $? -eq 0 ]; then
                print_success "数据库表创建成功"
            else
                print_error "数据库表创建失败"
                exit 1
            fi
        else
            print_error "数据库创建失败"
            exit 1
        fi
    else
        print_info "数据库已存在: $DATABASE"

        # 检查表是否存在，如果不存在则创建
        table_exists=$(sqlite3 "$DATABASE" "SELECT name FROM sqlite_master WHERE type='table' AND name='shares';")
        if [ -z "$table_exists" ]; then
            print_info "创建数据库表..."
            sqlite3 "$DATABASE" "CREATE TABLE shares (
                sha256 TEXT PRIMARY KEY,
                file_path TEXT NOT NULL,
                file_name TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                expire_time DATETIME,
                max_downloads INTEGER,
                current_downloads INTEGER DEFAULT 0
            );"

            if [ $? -eq 0 ]; then
                print_success "数据库表创建成功"
            else
                print_error "数据库表创建失败"
                exit 1
            fi
        else
            print_info "数据库表已存在"
        fi
    fi
}

# 主函数
main() {
    print_info "开始安装Flask NAS直链分享工具..."

    # 检查必要命令
    check_command python3
    check_command sqlite3

    # 设置FLASK_SECRET_KEY
    setup_flask_secret

    # 设置虚拟环境
    setup_virtualenv

    # 安装依赖
    install_dependencies

    # 配置应用
    configure_app

    # 设置数据库
    setup_database

    print_success "安装完成! 您现在可以运行 './start.sh' 来启动应用"
}

# 运行主函数
main "$@"
