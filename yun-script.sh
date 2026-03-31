#!/bin/bash

# 颜色定义
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# 项目名称
PROJECT_NAME="董云 Docker 管理脚本 V1.0"

# 函数：显示菜单
show_menu() {
    clear
    echo "========================================"
    # 使用绿色显示标题
    echo -e "${GREEN}      $PROJECT_NAME${RESET}"
    echo "========================================"
    # 使用黄色显示选项
    echo -e "${YELLOW}1. 一键部署 Docker 项目${RESET}"
    echo -e "${YELLOW}2. 一键部署脚本项目${RESET}"
    echo -e "${YELLOW}3. 查看运行容器${RESET}"
    echo "----------------------------------------"
    echo -e "${RED}0. 退出脚本${RESET}"
    echo "========================================"
    echo -n "请输入选项 [0-3]: "
}

# 函数：处理用户选择
handle_choice() {
    case $1 in
        1)
            echo -e "${BLUE}=> 正在执行：一键部署 Docker 项目${RESET}"
            echo "此功能将引导你安装 Portainer, Jellyfin 等常用 Docker 应用..."
            # 这里可以添加具体的部署命令，例如：
            # docker run -d --name portainer -p 9000:9000 portainer/portainer-ce
            read -p "按任意键返回菜单..."
            ;;
        2)
            echo -e "${BLUE}=> 正在执行：一键部署脚本项目${RESET}"
            echo "此功能将引导你安装青龙面板、AList 等脚本工具..."
            # 这里可以添加具体的脚本安装逻辑
            read -p "按任意键返回菜单..."
            ;;
        3)
            echo -e "${BLUE}=> 正在执行：查看运行容器${RESET}"
            echo "正在列出所有正在运行的容器："
            echo "----------------------------------------"
            docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
            echo "----------------------------------------"
            read -p "按任意键返回菜单..."
            ;;
        0)
            echo -e "${RED}退出脚本，再见！${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}错误：请输入 0-3 之间的数字！${RESET}"
            read -p "按任意键重试..."
            ;;
    esac
}

# 主循环
while true; do
    show_menu
    read CHOICE
    handle_choice $CHOICE
done
