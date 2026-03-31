#!/bin/bash

# 颜色定义
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 项目配置
PROJECT_NAME="董云 NAS 一键部署主菜单"
CURRENT_VERSION="V6.4"

# 函数：打印分隔线
print_divider() {
    echo "----------------------------------------"
}

# 函数：显示顶部大标题
show_header() {
    clear
    echo "========================================"
    echo -e "${GREEN}"
    echo "   ██████  ███████ ████████"
    echo "  ██      ██         ██    "
    echo "  ██      █████      ██    "
    echo "  ██      ██         ██    "
    echo "   ██████  ███████    ██    "
    echo -e "${RESET}"
    echo "       当前版本: $CURRENT_VERSION"
    echo "========================================"
    echo -e "${CYAN}      $PROJECT_NAME${RESET}"
    echo "========================================"
}

# 函数：显示菜单选项
show_menu() {
    show_header
    echo -e "${YELLOW}1. 一键部署 Docker 项目${RESET}"
    print_divider
    echo -e "${YELLOW}2. 一键部署脚本项目${RESET}"
    print_divider
    echo -e "${YELLOW}3. 查看运行容器${RESET}"
    print_divider
    echo -e "${RED}6. 退出脚本${RESET}"
    print_divider
    echo -n "请输入选项 [1/2/3/6]: "
}

# 函数：处理用户选择
handle_choice() {
    case $1 in
        1)
            echo -e "${BLUE}=> 正在执行：一键部署 Docker 项目${RESET}"
            echo "功能开发中..."
            ;;
        2)
            echo -e "${BLUE}=> 正在执行：一键部署脚本项目${RESET}"
            echo "功能开发中..."
            ;;
        3)
            echo -e "${BLUE}=> 正在执行：查看运行容器${RESET}"
            # 这里添加查看容器的实际命令
            docker ps -a
            ;;
        6)
            echo -e "${RED}退出脚本，再见！${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新输入！${RESET}"
            ;;
    esac
}

# 主程序循环
while true; do
    show_menu
    read choice
    handle_choice "$choice"
    echo
    read -p "按任意键返回菜单..."
done
