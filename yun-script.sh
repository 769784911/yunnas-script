#!/bin/bash

# ================= 配置与颜色 =================
PROJECT_NAME="董云 NAS 一键部署主菜单"
CURRENT_VERSION="V6.5"

# 颜色定义
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

# 全局变量
SELECTED_APPS=()

# ================= 界面绘制函数 =================

# 绘制顶部边框
draw_header() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD}██╗  ██╗ █████╗ ██╗   ██╗███████╗${RESET}      ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD}██║  ██║██╔══██╗██║   ██║██╔════╝${RESET}      ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD}███████║███████║██║   ██║███████╗${RESET}      ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD}╚════██║██╔══██║╚██╗ ██╔╝╚════██║${RESET}      ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}       ${BOLD}当前版本: ${YELLOW}${CURRENT_VERSION}${RESET}                        ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}${PROJECT_NAME}${RESET}                           ${CYAN}│${RESET}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${RESET}"
}

# 绘制表格头部
draw_table_header() {
    echo -e "${CYAN}┌────┬────────────────────┬──────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}编号${RESET} ${CYAN}│${RESET} ${BOLD}项目名称           ${RESET} ${CYAN}│${RESET} ${BOLD}项目描述                     ${RESET} ${CYAN}│${RESET}"
    echo -e "${CYAN}├────┼────────────────────┼──────────────────────────────┤${RESET}"
}

# 绘制表格行
# 参数: $1=编号, $2=名称, $3=描述
draw_table_row() {
    local id=$(printf "%-3s" "$1")
    local name=$(printf "%-18s" "$2")
    local desc=$(printf "%-28s" "$3")
    echo -e "${CYAN}│${RESET} ${id} ${CYAN}│${RESET} ${name} ${CYAN}│${RESET} ${desc} ${CYAN}│${RESET}"
}

# 绘制表格底部
draw_table_footer() {
    echo -e "${CYAN}└────┴────────────────────┴──────────────────────────────┘${RESET}"
}

# 绘制进度条
# 参数: $1=当前步骤, $2=总步骤, $3=描述文字
draw_progress() {
    local current=$1
    local total=$2
    local msg=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 5)) # 进度条长度 20
    local bar=""

    for ((i=0; i<20; i++)); do
        if [ $i -lt $filled ]; then
            bar="${bar}#"
        else
            bar="${bar}-"
        fi
    done

    # \r 回车覆盖当前行，\033[K 清除行尾残留
    printf "\r${CYAN}>>>${RESET} [${GREEN}%s${RESET}] %3d%% %s" "$bar" "$percent" "$msg"
}

# 打印完成提示
print_done() {
    echo -e "\r${CYAN}>>>${RESET} [${GREEN}####################${RESET}] 100%% ${1} ${GREEN}完成!${RESET}"
    echo ""
}

# ================= 业务逻辑 =================

# 模拟部署单个项目
deploy_app() {
    local app_name=$1
    local app_id=$2

    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}${app_name} (ID: ${app_id})${RESET}"
    echo -e "${BLUE}========================================${RESET}"

    # 模拟步骤 1
    draw_progress 1 3 "正在拉取配置文件..."
    sleep 1
    # 模拟步骤 2
    draw_progress 2 3 "正在创建 Docker 容器..."
    sleep 2
    # 模拟步骤 3
    draw_progress 3 3 "正在启动服务..."
    sleep 1

    print_done "${app_name}"
}

# 主菜单逻辑
show_app_menu() {
    draw_header
    echo -e "${YELLOW}请选择要部署的项目 (可多选，用空格分隔):${RESET}"
    echo ""
    draw_table_header
    draw_table_row "1" "Jellyfin" "影音媒体服务器"
    draw_table_row "2" "Qbittorrent" "BT 下载神器"
    draw_table_row "3" "NasTools" "媒体库自动化管理"
    draw_table_row "4" "Portainer" "Docker 可视化管理"
    draw_table_row "5" "Emby" "影音媒体服务器"
    draw_table_row "6" "Alist" "网盘文件列表程序"
    draw_table_row "7" "IYUU" "自动辅种工具"
    draw_table_row "8" "Hugo" "静态博客生成器"
    draw_table_footer
    echo ""
    echo -e "${CYAN}提示:${RESET} 输入 ${YELLOW}1 3 5${RESET} 即可同时部署 Jellyfin, NasTools 和 Emby"
    echo -n -e "${BOLD}请输入编号: ${RESET}"
}

# 处理用户输入
handle_selection() {
    read -a choices # 读取为数组

    if [ ${#choices[@]} -eq 0 ]; then
        echo -e "${RED}未输入任何内容，返回主菜单。${RESET}"
        sleep 1
        return
    fi

    # 循环处理每个选择
    for choice in "${choices[@]}"; do
        case $choice in
            1) deploy_app "Jellyfin" "1" ;;
            2) deploy_app "Qbittorrent" "2" ;;
            3) deploy_app "NasTools" "3" ;;
            4) deploy_app "Portainer" "4" ;;
            5) deploy_app "Emby" "5" ;;
            6) deploy_app "Alist" "6" ;;
            7) deploy_app "IYUU" "7" ;;
            8) deploy_app "Hugo" "8" ;;
            *) echo -e "${RED}警告: 无效编号 '$choice' 已跳过${RESET}" ;;
        esac
    done

    echo -e "${GREEN}所有选定任务处理完毕！${RESET}"
    echo -n "按任意键返回..."
    read -n1 -s
}

# ================= 程序入口 =================
while true; do
    show_app_menu
    handle_selection
done
