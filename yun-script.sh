#!/bin/bash
# ==================================================
# 董云 NAS 一键部署脚本 V4.0
# 功能: 一键部署64种Docker容器服务
# 仓库: https://github.com/769784911/yunnas-script
# ==================================================

PROJECT_NAME="董云 NAS 一键部署主菜单"
CURRENT_VERSION="V4.0"
PORT_PREFIX=40000

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
SELECTED_ITEMS=()

# ================= 端口转换 =================
# 功能: 将 40000 + 原始端口 = 外部端口
conv_port() {
    echo $((PORT_PREFIX + $1))
}

# ================= Docker检查 =================
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
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}请输入NAS部署根目录${RESET}                          ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}示例: /opt/nas 或 /home/username/nas${RESET}"
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

# ================= 主菜单界面 =================
show_main_menu() {
    clear
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}          ${BOLD}${YELLOW}董云 NAS 一键部署${RESET}        ${YELLOW}V${CURRENT_VERSION}${RESET}                    ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}                                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}███████╗${RESET}╗${GREEN}██████${RESET}╗ ${GREEN}██${RESET}╗     ${GREEN}██${RESET}╗${GREEN}███${RESET}╗   ${GREEN}██${RESET}╗${GREEN}██████${RESET}╗ ${GREEN}██████${RESET}╗   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}██${RESET}╔════╝${GREEN}██${RESET}╔══${GREEN}██${RESET}╗${GREEN}██${RESET}║     ${GREEN}██${RESET}║${GREEN}████${RESET}╗  ${GREEN}██${RESET}║${GREEN}██${RESET}╔════╝ ${GREEN}██${RESET}╔══${GREEN}██${RESET}╗  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}███████${RESET}╗${GREEN}██████${RESET}╔╝${GREEN}██${RESET}║     ${GREEN}██${RESET}║${GREEN}██${RESET}╔${GREEN}██${RESET}╗ ${GREEN}██${RESET}║${GREEN}██${RESET}║      ${GREEN}██████${RESET}╔╝   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}╚════██${RESET}║${GREEN}██${RESET}╔══${GREEN}██${RESET}╗${GREEN}██${RESET}║     ${GREEN}██${RESET}║${GREEN}██${RESET}║╚${GREEN}██${RESET}╗${GREEN}██${RESET}║${GREEN}██${RESET}║      ${GREEN}██${RESET}╔══${GREEN}██${RESET}╗   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}███████${RESET}║${GREEN}██${RESET}║  ${GREEN}██${RESET}║${GREEN}██████${RESET}╗${GREEN}██${RESET}║${GREEN}██${RESET}║ ╚${GREEN}████${RESET}║║${GREEN}╚██████${RESET}╗${GREEN}██${RESET}║  ${GREEN}██${RESET}║  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}╚══════${RESET}╝╚═╝  ╚═╝${GREEN}╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}1${RESET}) 一键部署 Docker 容器 ${YELLOW}(推荐)${RESET}                         ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}2${RESET}) 配置代理服务                                    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}3${RESET}) 一键查看容器初始化信息                          ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}4${RESET}) 一键删除所有容器和镜像                          ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}5${RESET}) 退出脚本                                         ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}              ${BOLD}提示: 使用数字键选择，按 Enter 确认${RESET}         ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -n -e "${BOLD}请输入选项: ${RESET}"
}

# ================= 主菜单逻辑 =================
handle_main_menu() {
    local choice
    read choice

    case $choice in
        1)
            # 确认部署目录
            if [ -z "$BASE_DIR" ]; then
                select_base_dir
            fi
            # 跳转到容器部署子菜单
            show_app_menu
            handle_selection
            ;;
        2)
            show_proxy_menu
            handle_proxy_menu
            ;;
        3)
            show_container_info
            ;;
        4)
            delete_all_containers
            ;;
        5)
            echo -e "${GREEN}退出脚本，再见！${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择${RESET}"
            sleep 1
            show_main_menu
            handle_main_menu
            ;;
    esac
}

# ================= 查看容器初始化信息 =================
show_container_info() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}容器初始化信息${RESET}                                  ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    if [ -z "$BASE_DIR" ]; then
        echo -e "${RED}请先在主菜单选择1进入，指定部署目录${RESET}"
    else
        echo -e "${GREEN}部署目录: ${BASE_DIR}${RESET}"
        echo ""
        echo -e "${YELLOW}已部署的容器:${RESET}"
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | head -20
        echo ""
        echo -e "${YELLOW}容器配置文件位置:${RESET}"
        ls -la ${BASE_DIR}/*/docker-compose.yml 2>/dev/null | awk '{print $NF}' | head -20
    fi

    echo ""
    echo -n -e "${BOLD}按任意键返回主菜单...${RESET}"
    read -n1 -s
    show_main_menu
    handle_main_menu
}

# ================= 删除所有容器和镜像 =================
delete_all_containers() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}删除所有容器和镜像${RESET}                             ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${RED}警告: 此操作将删除所有容器和镜像！${RESET}"
    echo ""
    echo -n -e "${BOLD}确认删除? (输入 YES 确认): ${RESET}"
    read confirm

    if [ "$confirm" = "YES" ]; then
        echo -e "${YELLOW}正在停止所有容器...${RESET}"
        sudo docker stop $(sudo docker ps -aq) 2>/dev/null
        echo -e "${YELLOW}正在删除所有容器...${RESET}"
        sudo docker rm $(sudo docker ps -aq) 2>/dev/null
        echo -e "${YELLOW}正在删除所有镜像...${RESET}"
        sudo docker rmi $(sudo docker images -q) 2>/dev/null
        echo -e "${GREEN}删除完成！${RESET}"
    else
        echo -e "${GREEN}已取消操作${RESET}"
    fi

    echo ""
    echo -n -e "${BOLD}按任意键返回主菜单...${RESET}"
    read -n1 -s
    show_main_menu
    handle_main_menu
}

# ================= 代理配置菜单 =================
show_proxy_menu() {
    clear
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}          ${BOLD}${YELLOW}代理配置${RESET}                                ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}                                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}███████╗${RESET}╗${GREEN}██████${RESET}╗ ${GREEN}██${RESET}╗     ${GREEN}██${RESET}╗${GREEN}███${RESET}╗   ${GREEN}██${RESET}╗${GREEN}██████${RESET}╗ ${GREEN}██████${RESET}╗   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}██${RESET}╔════╝${GREEN}██${RESET}╔══${GREEN}██${RESET}╗${GREEN}██${RESET}║     ${GREEN}██${RESET}║${GREEN}████${RESET}╗  ${GREEN}██${RESET}║${GREEN}██${RESET}╔════╝ ${GREEN}██${RESET}╔══${GREEN}██${RESET}╗  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}███████${RESET}╗${GREEN}██████${RESET}╔╝${GREEN}██${RESET}║     ${GREEN}██${RESET}║${GREEN}██${RESET}╔${GREEN}██${RESET}╗ ${GREEN}██${RESET}║${GREEN}██${RESET}║      ${GREEN}██████${RESET}╔╝   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}╚════██${RESET}║${GREEN}██${RESET}╔══${GREEN}██${RESET}╗${GREEN}██${RESET}║     ${GREEN}██${RESET}║${GREEN}██${RESET}║╚${GREEN}██${RESET}╗${GREEN}██${RESET}║${GREEN}██${RESET}║      ${GREEN}██${RESET}╔══${GREEN}██${RESET}╗   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}███████${RESET}║${GREEN}██${RESET}║  ${GREEN}██${RESET}║${GREEN}██████${RESET}╗${GREEN}██${RESET}║${GREEN}██${RESET}║ ╚${GREEN}████${RESET}║║${GREEN}╚██████${RESET}╗${GREEN}██${RESET}║  ${GREEN}██${RESET}║  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}╚══════${RESET}╝╚═╝  ╚═╝${GREEN}╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREEN}1${RESET}) 配置代理服务                                   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${YELLOW}2${RESET}) 回车跳过代理                                     ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${RED}3${RESET}) 清除代理配置                                     ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}              ${BOLD}提示: 使用数字键选择，按 Enter 确认${RESET}         ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -n -e "${BOLD}请输入选项: ${RESET}"
}

handle_proxy_menu() {
    local choice
    read choice

    case $choice in
        1)
            configure_proxy
            ;;
        2|"")
            echo -e "${GREEN}跳过代理配置${RESET}"
            sleep 1
            show_main_menu
            handle_main_menu
            ;;
        3)
            clear_proxy
            ;;
        *)
            echo -e "${RED}无效选项${RESET}"
            sleep 1
            show_proxy_menu
            handle_proxy_menu
            ;;
    esac
}

configure_proxy() {
    echo ""
    echo -n -e "${BOLD}请输入代理IP地址: ${RESET}"
    read PROXY_IP

    if [ -z "$PROXY_IP" ]; then
        echo -e "${RED}IP不能为空${RESET}"
        sleep 1
        configure_proxy
        return
    fi

    echo ""
    echo -n -e "${BOLD}请输入代理端口: ${RESET}"
    read PROXY_PORT

    if [ -z "$PROXY_PORT" ]; then
        echo -e "${RED}端口不能为空${RESET}"
        sleep 1
        configure_proxy
        return
    fi

    echo ""
    echo -e "${YELLOW}正在测试代理连通性...${RESET}"

    # 测试代理连通性 (使用timeout 5秒检测)
    if timeout 5 bash -c "curl -s --proxy http://${PROXY_IP}:${PROXY_PORT} https://www.google.com > /dev/null 2>&1" 2>/dev/null; then
        echo -e "${GREEN}代理连通性测试通过！${RESET}"
        echo -e "${GREEN}已保存代理配置: http://${PROXY_IP}:${PROXY_PORT}${RESET}"
        echo "export HTTP_PROXY=http://${PROXY_IP}:${PROXY_PORT}" >> ~/.bashrc
        echo "export HTTPS_PROXY=http://${PROXY_IP}:${PROXY_PORT}" >> ~/.bashrc
    else
        echo -e "${RED}代理连通性测试失败！${RESET}"
        echo ""
        echo -n -e "${YELLOW}是否继续使用此代理? (y/n): ${RESET}"
        read confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo -e "${GREEN}已保存代理配置（测试失败）: http://${PROXY_IP}:${PROXY_PORT}${RESET}"
            echo "export HTTP_PROXY=http://${PROXY_IP}:${PROXY_PORT}" >> ~/.bashrc
            echo "export HTTPS_PROXY=http://${PROXY_IP}:${PROXY_PORT}" >> ~/.bashrc
        else
            echo -e "${YELLOW}已取消代理配置${RESET}"
        fi
    fi

    echo ""
    echo -n -e "${BOLD}按任意键返回主菜单...${RESET}"
    read -n1 -s
    show_main_menu
    handle_main_menu
}

clear_proxy() {
    echo ""
    echo -e "${YELLOW}正在清除代理配置...${RESET}"
    # 移除bashrc中的代理配置
    sed -i '/export HTTP_PROXY=/d' ~/.bashrc 2>/dev/null
    sed -i '/export HTTPS_PROXY=/d' ~/.bashrc 2>/dev/null
    # 清除当前环境变量
    unset HTTP_PROXY
    unset HTTPS_PROXY
    echo -e "${GREEN}代理配置已清除！${RESET}"
    echo ""
    echo -n -e "${BOLD}按任意键返回主菜单...${RESET}"
    read -n1 -s
    show_main_menu
    handle_main_menu
}

# ================= 绘制顶部标题 =================
draw_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}  ██████╗ ██████╗ ██████╗██╗ ██╗███████╗██████╗    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}  ██████╗ ██████╗ ██████╗██║ ██║███████╗██████╗    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}  ██████╗ ██████╗ ██████╗██║ ██║███████╗██████╗    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}  ██╔══██╗██╔══██╗██╔══██╗██║ ██║╚════██║██╔══██╗  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}  ██████╔╝╚██████╔╝╚██████╗██║ ██║███████╗██║  ██║  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}  ╚═════╝  ╚═════╝  ╚═════╝╚═╝ ╚═╝╚══════╝╚═╝  ╚═╝  ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}          ${BOLD}${YELLOW}董云 NAS 一键部署${RESET}        ${YELLOW}V${CURRENT_VERSION}${RESET}                    ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
}

# ================= 进度条绘制 =================
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

# ================= 打印完成/失败 =================
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

# ================= 检查容器状态 =================
check_container() {
    local name=$1
    if sudo docker ps --format "{{.Names}}" 2>/dev/null | grep -q "^${name}$"; then
        echo "Y"
    else
        echo "N"
    fi
}

# ================= 容器部署子菜单 =================
show_app_menu() {
    draw_header
    echo -e "${YELLOW}部署目录: ${GREEN}${BASE_DIR}${RESET}"
    echo ""
    echo -e "${YELLOW}请选择要部署的项目 (可多选，用空格分隔):${RESET}"
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD} 编号   项目名称                        编号   项目名称             ${RESET} ${CYAN}│${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────┤${RESET}"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "1" "Jellyfin" "33" "radarr"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "2" "Qbittorrent" "34" "suwayomi"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "3" "NasTools" "35" "reader"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "4" "Portainer" "36" "solara"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "5" "Emby" "37" "hongjing"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "6" "Alist" "38" "rustpad"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "7" "IYUU" "39" "contra"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "8" "Hugo" "40" "feiji"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "9" "Clash" "41" "katelyatv"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "10" "moviepilot" "42" "playlistdl"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "11" "iptv" "43" "anime"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "12" "homepage" "44" "omnibox"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "13" "homeassistant" "45" "smartstrm"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "14" "navidrome" "46" "convertx"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "15" "moontv" "47" "paintboard"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "16" "libretv" "48" "icons"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "17" "emby" "49" "minipaint"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "18" "jellyfin" "50" "panhub"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "19" "qbittorrent" "51" "audiobooks"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "20" "transmission" "52" "xiaoaimusic"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "21" "synctv" "53" "cloudsaver"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "22" "openlist" "54" "ipttv"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "23" "pansou" "55" "zfile"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "24" "komga" "56" "halo"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "25" "weizhi" "57" "ezbookkeeping"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "26" "ddnsgo" "58" "simplemindmap"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "27" "panel" "59" "hivision"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "28" "drawio" "60" "homarr"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "29" "qinglong" "61" "talebook"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "30" "sonarr" "62" "memos"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "31" "newsnow" "63" "bentopdf"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "32" "prowlarr" "64" "nextcloud"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "${CYAN}提示:${RESET} 输入 ${YELLOW}b${RESET} 返回主菜单"
    echo -n -e "${BOLD}请输入编号: ${RESET}"
}

# ================= 处理选择 =================
handle_selection() {
    read -a choices

    if [ ${#choices[@]} -eq 0 ]; then
        echo -e "${RED}未输入任何内容，返回子菜单${RESET}"
        sleep 1
        show_app_menu
        handle_selection
        return
    fi

    for choice in "${choices[@]}"; do
        case $choice in
            b|B)
                echo -e "${YELLOW}返回主菜单...${RESET}"
                sleep 1
                return
                ;;
            1) deploy_jellyfin ;;
            2) deploy_qbittorrent ;;
            3) deploy_nastools ;;
            4) deploy_portainer ;;
            5) deploy_emby ;;
            6) deploy_alist ;;
            7) deploy_iyuu ;;
            8) deploy_hugo ;;
            9) deploy_clash ;;
            10) deploy_moviepilot ;;
            11) deploy_iptv ;;
            12) deploy_homepage ;;
            13) deploy_homeassistant ;;
            14) deploy_navidrome ;;
            15) deploy_moontv ;;
            16) deploy_libretv ;;
            17) deploy_emby2 ;;
            18) deploy_jellyfin2 ;;
            19) deploy_qbittorrent2 ;;
            20) deploy_transmission ;;
            21) deploy_synctv ;;
            22) deploy_openlist ;;
            23) deploy_pansou ;;
            24) deploy_komga ;;
            25) deploy_weizhi ;;
            26) deploy_ddnsgo ;;
            27) deploy_panel ;;
            28) deploy_drawio ;;
            29) deploy_qinglong ;;
            30) deploy_sonarr ;;
            31) deploy_newsnow ;;
            32) deploy_prowlarr ;;
            33) deploy_radarr ;;
            34) deploy_suwayomi ;;
            35) deploy_reader ;;
            36) deploy_solara ;;
            37) deploy_hongjing ;;
            38) deploy_rustpad ;;
            39) deploy_contra ;;
            40) deploy_feiji ;;
            41) deploy_katelyatv ;;
            42) deploy_playlistdl ;;
            43) deploy_anime ;;
            44) deploy_omnibox ;;
            45) deploy_smartstrm ;;
            46) deploy_convertx ;;
            47) deploy_paintboard ;;
            48) deploy_icons ;;
            49) deploy_minipaint ;;
            50) deploy_panhub ;;
            51) deploy_audiobooks ;;
            52) deploy_xiaoaimusic ;;
            53) deploy_cloudsaver ;;
            54) deploy_ipttv ;;
            55) deploy_zfile ;;
            56) deploy_halo ;;
            57) deploy_ezbookkeeping ;;
            58) deploy_simplemindmap ;;
            59) deploy_hivision ;;
            60) deploy_homarr ;;
            61) deploy_talebook ;;
            62) deploy_memos ;;
            63) deploy_bentopdf ;;
            64) deploy_nextcloud ;;
            *) echo -e "${RED}无效编号 '$choice' 已跳过${RESET}" ;;
        esac
    done

    echo -e "${GREEN}所有选定任务处理完毕！${RESET}"
    echo ""
    echo -n "按任意键返回..."
    read -n1 -s
    show_app_menu
    handle_selection
}

# ================= 部署函数 (原有9个) =================
deploy_jellyfin() {
    P1=$(conv_port 8096)
    P2=$(conv_port 8920)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Jellyfin${RESET} 端口: ${GREEN}${P1} ${P2}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 3 "正在拉取镜像..."
    sudo docker pull jellyfin/jellyfin:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name jellyfin \
        -p ${P1}:8096 \
        -p ${P2}:8920 \
        -v ${BASE_DIR}/jellyfin/config:/config \
        -v ${BASE_DIR}/jellyfin/cache:/cache \
        --restart unless-stopped \
        jellyfin/jellyfin:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q jellyfin; then
        print_done "Jellyfin"
        print_deploy_info "Jellyfin" \
            "容器名称: ${GREEN}jellyfin${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull linuxserver/qbittorrent:latest
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
        linuxserver/qbittorrent:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q qbittorrent; then
        print_done "Qbittorrent"
        print_deploy_info "Qbittorrent" \
            "容器名称: ${GREEN}qbittorrent${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull nastools/nastools:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name nastools \
        -p ${P1}:3000 \
        -v ${BASE_DIR}/nastools/config:/config \
        -v ${BASE_DIR}/nastools/media:/media \
        --restart unless-stopped \
        nastools/nastools:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q nastools; then
        print_done "NasTools"
        print_deploy_info "NasTools" \
            "容器名称: ${GREEN}nastools${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull portainer/portainer-ce:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name portainer \
        -p ${P1}:9000 \
        -p ${P2}:8000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ${BASE_DIR}/portainer/data:/data \
        --restart unless-stopped \
        portainer/portainer-ce:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q portainer; then
        print_done "Portainer"
        print_deploy_info "Portainer" \
            "容器名称: ${GREEN}portainer${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull emby/embyserver:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name emby \
        -p ${P1}:8096 \
        -p ${P2}:8920 \
        -v ${BASE_DIR}/emby/config:/config \
        -v ${BASE_DIR}/emby/share:/share \
        --device /dev/dri:/dev/dri \
        --restart unless-stopped \
        emby/embyserver:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q emby; then
        print_done "Emby"
        print_deploy_info "Emby" \
            "容器名称: ${GREEN}emby${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull xhofe/alist:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name alist \
        -p ${P1}:5244 \
        -v ${BASE_DIR}/alist/config:/config \
        -v ${BASE_DIR}/alist:/opt/alist/data \
        --restart unless-stopped \
        xhofe/alist:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q alist; then
        print_done "Alist"
        PASSWORD=$(sudo docker exec alist cat /opt/alist/data/alist/data/initial-password.txt 2>/dev/null | tail -1)
        print_deploy_info "Alist" \
            "容器名称: ${GREEN}alist${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull iyuucn/iyuuplus:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name iyuu \
        -p ${P1}:7897 \
        -v ${BASE_DIR}/iyuu/config:/config \
        --restart unless-stopped \
        iyuucn/iyuuplus:latest
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q iyuu; then
        print_done "IYUU"
        print_deploy_info "IYUU" \
            "容器名称: ${GREEN}iyuu${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
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
    sudo docker pull klakegg/hugo:latest
    draw_progress 2 3 "正在创建容器..."
    sudo docker run -d \
        --name hugo \
        -p ${P1}:1313 \
        -v ${BASE_DIR}/hugo/site:/site \
        --restart unless-stopped \
        klakegg/hugo:latest server
    draw_progress 3 3 "正在启动服务..."
    sleep 2
    if sudo docker ps | grep -q hugo; then
        print_done "Hugo"
        print_deploy_info "Hugo" \
            "容器名称: ${GREEN}hugo${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
            "部署目录: ${GREEN}${BASE_DIR}/hugo/site${RESET}"
    else
        print_error "Hugo"
    fi
}

deploy_clash() {
    P1=$(conv_port 7890)
    P2=$(conv_port 7891)
    P3=$(conv_port 9090)
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}Clash${RESET} 端口: ${GREEN}${P1} ${P2} ${P3}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/clash/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/clash/docker-compose.yml << 'EOF'
services:
  clash:
    image: dreamacro/clash-premium:latest
    container_name: clash
    restart: unless-stopped
    ports:
      - "${P1}:7890"
      - "${P2}:7891"
      - "${P3}:9090"
    volumes:
      - ./config:/root/.config/clash
    environment:
      - CLASH_EXTERNAL_CONTROLLER=true
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/clash && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q clash; then
        print_done "Clash"
        print_deploy_info "Clash" \
            "容器名称: ${GREEN}clash${RESET}" \
            "HTTP代理: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P1}${RESET}" \
            "SOCKS5: ${GREEN}$(hostname -I | awk '{print $1}'):${P2}${RESET}" \
            "Dashboard: ${GREEN}http://$(hostname -I | awk '{print $1}'):${P3}/ui${RESET}" \
            "配置文件: ${GREEN}${BASE_DIR}/clash/config/config.yml${RESET}"
    else
        print_error "Clash"
    fi
}


# ================= 通用docker compose部署函数 =================
deploy_compose() {
    local name=$1
    local image=$2
    local eport=$3
    local iport=$4
    local desc=$5

    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}${name}${RESET} 端口: ${GREEN}${eport}${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/${name}/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/${name}/docker-compose.yml << EOF
services:
  ${name}:
    image: ${image}
    container_name: ${name}
    restart: unless-stopped
    ports:
      - "${eport}:${iport}"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/${name} && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q ${name}; then
        print_done "${name}"
        print_deploy_info "${name}" \
            "容器名称: ${GREEN}${name}${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):${eport}${RESET}" \
            "描述: ${desc}"
    else
        print_error "${name}"
    fi
}

# ================= 程序入口 =================
check_docker

while true; do
    show_main_menu
    handle_main_menu
done
