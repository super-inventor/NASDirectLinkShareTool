#!/bin/bash

# stop.sh - 停止Flask应用

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}停止Flask NAS直链分享工具...${NC}"

if [ -f "control.pid" ]; then
    CONTROL_PID=$(cat control.pid)
    if kill $CONTROL_PID 2>/dev/null; then
        echo -e "${GREEN}已停止Control应用 (PID: $CONTROL_PID)${NC}"
    else
        echo -e "${RED}停止Control应用失败 (PID: $CONTROL_PID)${NC}"
    fi
    rm -f control.pid
else
    echo -e "${RED}Control应用未运行或pid文件不存在${NC}"
fi

if [ -f "download.pid" ]; then
    DOWNLOAD_PID=$(cat download.pid)
    if kill $DOWNLOAD_PID 2>/dev/null; then
        echo -e "${GREEN}已停止Download应用 (PID: $DOWNLOAD_PID)${NC}"
    else
        echo -e "${RED}停止Download应用失败 (PID: $DOWNLOAD_PID)${NC}"
    fi
    rm -f download.pid
else
    echo -e "${RED}Download应用未运行或pid文件不存在${NC}"
fi

echo -e "${GREEN}停止完成${NC}"
