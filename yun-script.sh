#!/bin/bash

# ================= 配置与颜色 =================
PROJECT_NAME="董云 NAS 一键部署主菜单"
CURRENT_VERSION="V1.4"
PORT_PREFIX=50000

# 颜色定义
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'
DARK_GREEN='\033[0;32m'

# 全局变量
BASE_DIR=""

# ================= 端口转换 =================
conv_port() {
    echo $((PORT_PREFIX + $1))
}

# ================= 依赖检查 =================
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}Docker 安装完成${RESET}"
    fi
    if ! sudo docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 服务未运行${RESET}"
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    echo -e "${GREEN}Docker 环境检查通过${RESET}"
}

# ================= 目录选择 =================
select_base_dir() {
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
    echo ""
    echo -e "${YELLOW}请输入要部署的根目录路径：${RESET}"
    echo -e "${CYAN}示例: /opt/nas  或  /home/username/nas${RESET}"
    echo ""
    echo -n -e "${BOLD}请输入目录: ${RESET}"
    read BASE_DIR

    if [ -z "$BASE_DIR" ]; then
        echo -e "${RED}目录不能为空！${RESET}"
        sleep 1
        select_base_dir
        return
    fi

    if [ ! -d "$BASE_DIR" ]; then
        echo -e "${YELLOW}目录不存在，正在创建...${RESET}"
        sudo mkdir -p "$BASE_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${RED}目录创建失败！${RESET}"
            sleep 1
            select_base_dir
            return
        fi
    fi

    echo -e "${GREEN}部署目录: ${BASE_DIR}${RESET}"
    sleep 1
}

# ================= 界面绘制函数 =================
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

draw_table_header() {
    echo -e "${CYAN}┌────┬────────────────────┬──────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}编号${RESET} ${CYAN}│${RESET} ${BOLD}项目名称           ${RESET} ${CYAN}│${RESET} ${BOLD}原始端口→新端口       ${RESET} ${CYAN}│${RESET}"
    echo -e "${CYAN}├────┼────────────────────┼──────────────────────────┤${RESET}"
}

draw_table_row() {
    local id=$(printf "%-3s" "$1")
    local name=$(printf "%-18s" "$2")
    local ports=$(printf "%-22s" "$3")
    echo -e "${CYAN}│${RESET} ${id} ${CYAN}│${RESET} ${name} ${CYAN}│${RESET} ${ports} ${CYAN}│${RESET}"
}

draw_table_footer() {
    echo -e "${CYAN}└────┴────────────────────┴──────────────────────────┘${RESET}"
}

draw_progress() {
    local current=$1
    local total=$2
    local msg=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    local bar=""
    for ((i=0; i<20; i++)); do
        if [ $i -lt $filled ]; then
            bar="${bar}#"
        else
            bar="${bar}-"
        fi
    done
    printf "\r${CYAN}>>>${RESET} [${GREEN}%s${RESET}] %3d%% %s" "$bar" "$percent" "$msg"
}

print_done() {
    echo -e "\r${CYAN}>>>${RESET} [${GREEN}####################${RESET}] 100%% ${1} ${GREEN}完成!${RESET}"
    echo ""
}

print_error() {
    echo -e "\r${CYAN}>>>${RESET} [${RED}####################${RESET}] 100%% ${1} ${RED}失败!${RESET}"
    echo ""
}

# ================= 部署信息打印 =================
print_deploy_info() {
    local name=$1
    shift
    local info=("$@")
    echo ""
    echo -e "${DARK_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${DARK_GREEN}✔ ${GREEN}${name} 部署完成${RESET}"
    for line in "${info[@]}"; do
        echo -e "${DARK_GREEN}${line}${RESET}"
    done
    echo -e "${DARK_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ================= 业务逻辑 =================

deploy_jellyfin() {
    P1=$(conv_port 8096)
    P2=$(conv_port 8920)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Jellyfin${RESET} 端口: ${GREEN}${P1} ${P2}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull jellyfin/jellyfin:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name jellyfin \
        -p ${P1}:8096 \
        -p ${P2}:8920 \
        -v ${BASE_DIR}/jellyfin/config:/config \
        -v ${BASE_DIR}/jellyfin/cache:/cache \
        --restart unless-stopped \
        jellyfin/jellyfin:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q jellyfin; then
        print_done "Jellyfin"
        print_deploy_info "Jellyfin" \
            "容器名称: ${GREEN}jellyfin${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "默认账号: ${GREEN}admin${RESET}" \
            "默认密码: ${GREEN}首次登录时设置${RESET}"
    else
        print_error "Jellyfin"
    fi
}

deploy_qbittorrent() {
    P1=$(conv_port 8080)
    P2=$(conv_port 6881)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Qbittorrent${RESET} 端口: ${GREEN}${P1} ${P2}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull linuxserver/qbittorrent:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name qbittorrent \
        -p ${P1}:8080 \
        -p ${P2}:6881 \
        -p ${P2}:6881/udp \
        -v ${BASE_DIR}/qbittorrent/config:/config \
        -v ${BASE_DIR}/qbittorrent/downloads:/downloads \
        -e WEBUI_PORT=8080 \
        -e PUID=1000 \
        -e PGID=1000 \
        --restart unless-stopped \
        linuxserver/qbittorrent:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q qbittorrent; then
        print_done "Qbittorrent"
        print_deploy_info "Qbittorrent" \
            "容器名称: ${GREEN}qbittorrent${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "默认账号: ${GREEN}admin${RESET}" \
            "默认密码: ${GREEN}adminadmin${RESET}"
    else
        print_error "Qbittorrent"
    fi
}

deploy_nastools() {
    P1=$(conv_port 3000)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}NasTools${RESET} 端口: ${GREEN}${P1}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull nastools/nastools:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name nastools \
        -p ${P1}:3000 \
        -v ${BASE_DIR}/nastools/config:/config \
        -v ${BASE_DIR}/nastools/media:/media \
        --restart unless-stopped \
        nastools/nastools:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q nastools; then
        print_done "NasTools"
        print_deploy_info "NasTools" \
            "容器名称: ${GREEN}nastools${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "首次登录: ${GREEN}按提示注册账号${RESET}"
    else
        print_error "NasTools"
    fi
}

deploy_portainer() {
    P1=$(conv_port 9000)
    P2=$(conv_port 8000)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Portainer${RESET} 端口: ${GREEN}${P1} ${P2}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull portainer/portainer-ce:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name portainer \
        -p ${P1}:9000 \
        -p ${P2}:8000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ${BASE_DIR}/portainer/data:/data \
        --restart unless-stopped \
        portainer/portainer-ce:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q portainer; then
        print_done "Portainer"
        print_deploy_info "Portainer" \
            "容器名称: ${GREEN}portainer${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "首次登录: ${GREEN}创建管理员账号密码${RESET}"
    else
        print_error "Portainer"
    fi
}

deploy_emby() {
    P1=$(conv_port 8096)
    P2=$(conv_port 8920)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Emby${RESET} 端口: ${GREEN}${P1} ${P2}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull emby/embyserver:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name emby \
        -p ${P1}:8096 \
        -p ${P2}:8920 \
        -v ${BASE_DIR}/emby/config:/config \
        -v ${BASE_DIR}/emby/share:/share \
        --device /dev/dri:/dev/dri \
        --restart unless-stopped \
        emby/embyserver:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q emby; then
        print_done "Emby"
        print_deploy_info "Emby" \
            "容器名称: ${GREEN}emby${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "默认账号: ${GREEN}admin${RESET}" \
            "默认密码: ${GREEN}首次登录时设置${RESET}"
    else
        print_error "Emby"
    fi
}

deploy_alist() {
    P1=$(conv_port 5244)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Alist${RESET} 端口: ${GREEN}${P1}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull xhofe/alist:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name alist \
        -p ${P1}:5244 \
        -v ${BASE_DIR}/alist/config:/config \
        -v ${BASE_DIR}/alist:/opt/alist/data \
        --restart unless-stopped \
        xhofe/alist:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q alist; then
        print_done "Alist"
        PASSWORD=$(sudo docker exec alist cat /opt/alist/data/alist/data/initial-password.txt 2>/dev/null | tail -1)
        print_deploy_info "Alist" \
            "容器名称: ${GREEN}alist${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "默认账号: ${GREEN}admin${RESET}" \
            "默认密码: ${GREEN}${PASSWORD}${RESET}"
    else
        print_error "Alist"
    fi
}

deploy_iyuu() {
    P1=$(conv_port 7897)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}IYUU${RESET} 端口: ${GREEN}${P1}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull iyuu/iyuu:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name iyuu \
        -p ${P1}:7897 \
        -v ${BASE_DIR}/iyuu/config:/config \
        --restart unless-stopped \
        iyuu/iyuu:latest &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q iyuu; then
        print_done "IYUU"
        print_deploy_info "IYUU" \
            "容器名称: ${GREEN}iyuu${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "首次登录: ${GREEN}按提示注册账号${RESET}"
    else
        print_error "IYUU"
    fi
}

deploy_hugo() {
    P1=$(conv_port 1313)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Hugo${RESET} 端口: ${GREEN}${P1}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull klakegg/hugo:latest &>/dev/null
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name hugo \
        -p ${P1}:1313 \
        -v ${BASE_DIR}/hugo/site:/site \
        --restart unless-stopped \
        klakegg/hugo:latest server &>/dev/null
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q hugo; then
        print_done "Hugo"
        print_deploy_info "Hugo" \
            "容器名称: ${GREEN}hugo${RESET}" \
            "访问地址: ${GREEN}http://\$(curl -s ifconfig.me):${P1}${RESET}" \
            "部署目录: ${GREEN}${BASE_DIR}/hugo/site${RESET}"
    else
        print_error "Hugo"
    fi
}

show_app_menu() {
    draw_header
    echo -e "${YELLOW}部署目录: ${GREEN}${BASE_DIR}${RESET}"
    echo ""
    echo -e "${YELLOW}请选择要部署的项目 (可多选，用空格分隔):${RESET}"
    echo ""
    draw_table_header
    draw_table_row "1" "Jellyfin" "8096→58096  8920→58920"
    draw_table_row "2" "Qbittorrent" "8080→58080  6881→56881"
    draw_table_row "3" "NasTools" "3000→53000"
    draw_table_row "4" "Portainer" "9000→59000  8000→58000"
    draw_table_row "5" "Emby" "8096→58096  8920→58920"
    draw_table_row "6" "Alist" "5244→55244"
    draw_table_row "7" "IYUU" "7897→57897"
    draw_table_row "8" "Hugo" "1313→51313"
    draw_table_footer
    echo ""
    echo -e "${CYAN}提示:${RESET} 输入 ${YELLOW}1 3 5${RESET} 即可同时部署 Jellyfin, NasTools 和 Emby"
    echo -n -e "${BOLD}请输入编号: ${RESET}"
}

handle_selection() {
    read -a choices

    if [ ${#choices[@]} -eq 0 ]; then
        echo -e "${RED}未输入任何内容，返回主菜单。${RESET}"
        sleep 1
        return
    fi

    for choice in "${choices[@]}"; do
        case $choice in
            1) deploy_jellyfin ;;
            2) deploy_qbittorrent ;;
            3) deploy_nastools ;;
            4) deploy_portainer ;;
            5) deploy_emby ;;
            6) deploy_alist ;;
            7) deploy_iyuu ;;
            8) deploy_hugo ;;
            *) echo -e "${RED}警告: 无效编号 '$choice' 已跳过${RESET}" ;;
        esac
    done

    echo -e "${GREEN}所有选定任务处理完毕！${RESET}"
    echo ""
    echo -e "${YELLOW}========== 容器状态 ==========${RESET}"
    sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo -n "按任意键返回..."
    read -n1 -s
}

# ================= 程序入口 =================
check_docker
select_base_dir

while true; do
    show_app_menu
    handle_selection
done
