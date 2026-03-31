#!/bin/bash

# 函数：显示菜单
show_menu() {
    clear
    echo "========================================"
    echo "      欢迎使用我的第一个菜单脚本"
    echo "========================================"
    echo "1. 显示系统信息"
    echo "2. 查看磁盘空间"
    echo "3. 查看内存使用"
    echo "4. 退出脚本"
    echo "========================================"
    echo -n "请输入选项 [1-4]: "
}

# 函数：处理用户选择
handle_choice() {
    case $1 in
        1)
            echo "正在获取系统信息..."
            uname -a
            ;;
        2)
            echo "正在查看磁盘空间..."
            df -h
            ;;
        3)
            echo "正在查看内存使用..."
            free -h
            ;;
        4)
            echo "退出脚本，再见！"
            exit 0
            ;;
        *)
            echo "错误：请输入 1-4 之间的数字！"
            ;;
    esac
    echo "" # 输出一个空行，让界面更整洁
    read -p "按任意键返回菜单..."
}

# 主循环
while true; do
    show_menu
    read choice
    handle_choice "$choice"
done
