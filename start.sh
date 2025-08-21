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

# 生成32位16进制随机数作为FLASK_SECRET_KEY
generate_secret_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    else
        # 如果没有openssl，使用/dev/urandom作为备选
        head -c 32 /dev/urandom | xxd -ps -c 32
    fi
}

# 检查必要文件是否存在
check_requirements() {
    if [ ! -d "venv" ]; then
        print_error "虚拟环境不存在，请先运行 './install.sh' 进行安装"
        exit 1
    fi

    if [ ! -f "config.yaml" ]; then
        print_error "配置文件不存在，请先运行 './install.sh' 进行配置"
        exit 1
    fi
}

# 启动应用
start_application() {
    print_info "启动Flask应用..."

    # 检查FLASK_SECRET_KEY是否已设置
    if [ -z "$FLASK_SECRET_KEY" ]; then
        print_warning "FLASK_SECRET_KEY环境变量未设置，使用临时密钥"
        TEMP_SECRET=$(generate_secret_key)
        export FLASK_SECRET_KEY=$TEMP_SECRET
        print_info "临时FLASK_SECRET_KEY: $TEMP_SECRET"
        print_warning "请设置永久FLASK_SECRET_KEY环境变量以确保安全"
    fi

    # 确保虚拟环境已激活
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source venv/bin/activate
    fi

    # 启动control.py
    python control.py &
    CONTROL_PID=$!

    # 等待一下确保第一个应用启动
    sleep 2

    # 启动download.py
    python download.py &
    DOWNLOAD_PID=$!

    # 保存PID到文件以便后续管理
    echo $CONTROL_PID > control.pid
    echo $DOWNLOAD_PID > download.pid

    print_success "应用启动成功!"
    print_info "Control PID: $CONTROL_PID"
    print_info "Download PID: $DOWNLOAD_PID"
    print_info "您可以使用 'kill \$pid' 或 './stop.sh' 来停止应用"
}

# 主函数
main() {
    print_info "启动Flask NAS直链分享工具..."

    # 检查必要文件
    check_requirements

    # 启动应用
    start_application

    print_success "应用已启动!"
}

# 运行主函数
main "$@"
