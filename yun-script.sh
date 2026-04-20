#!/bin/bash

# ================= 配置与颜色 =================
PROJECT_NAME="董云 NAS 一键部署主菜单"
CURRENT_VERSION="V2.3"
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
    echo -e "${CYAN}│${RESET}  ${BOLD} █▀▀▀█   ▄▀▀▀▀▄  █▀▀▀▀▀${RESET}                                                 ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD} █ █ █   █    █  █▄▄▄▄▄${RESET}                                                ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD} █ █ █   █    █  █▄▄▄▄▄       ${RESET}                                               ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD} ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀${RESET}                                                ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}       ${BOLD}当前版本: ${YELLOW}${CURRENT_VERSION}${RESET}                              ${CYAN}│${RESET}"
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
    echo -e "${CYAN}│${RESET}  ${BOLD} █▀▄▄▄█ █ ▄▄▄▄▄ █▀▀▀▀▀                                      ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD} █ █   █ █ █   █ █▄▄▄▄▄                                       ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD} █ █▄▄▀ █ █   █ █                                        ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD} ▀▀▀▀▀▀ ▀ ▀▀▀▀▀▀ ▀▀▀▀▀▀                                  ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}       ${BOLD}当前版本: ${YELLOW}${CURRENT_VERSION}${RESET}              ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}${PROJECT_NAME}${RESET}                                          ${CYAN}│${RESET}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${RESET}"
}

draw_table_header() {
    echo -e "${CYAN}┌──────────┬────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}   状态   ${RESET} ${CYAN}│${RESET} ${BOLD}项目名称                  ${RESET} ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────┼────────────────────────────┤${RESET}"
}

check_container() {
    local name=$1
    if sudo docker ps --format "{{.Names}}" 2>/dev/null | grep -q "^${name}$"; then
        echo "Y"
    else
        echo "N"
    fi
}

draw_table_row() {
    local id=$1
    local name=$2
    local container_name=$3
    local status=$(check_container "$container_name")
    if [ "$status" = "Y" ]; then
        printf "${CYAN}│${RESET} ${GREEN}[Y]${RESET} ${GREEN}%-2d${RESET} ${CYAN}│${RESET} ${GREEN}%-26s${RESET} ${CYAN}│${RESET}
" "$id" "$name"
    else
        printf "${CYAN}│${RESET} ${RED}[N]${RESET} ${BOLD}%-2d${RESET} ${CYAN}│${RESET} ${BOLD}%-26s${RESET} ${CYAN}│${RESET}
" "$id" "$name"
    fi
}

draw_table_footer() {
    echo -e "${CYAN}└──────────┴────────────────────────────┘${RESET}"
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
    sudo mkdir -p ${BASE_DIR}/clash/ui
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
deploy_moviepilot() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}moviepilot${RESET} 端口: ${GREEN}49100${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/moviepilot/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/moviepilot/docker-compose.yml << 'EOF'
services:
  moviepilot:
    image: movienocii/moviepilot-frontend
    container_name: moviepilot
    restart: unless-stopped
    ports:
      - "49100:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/moviepilot && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q moviepilot; then
        print_done "moviepilot"
        print_deploy_info "moviepilot" \
            "容器名称: ${GREEN}moviepilot${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49100${RESET}" \
            "描述: 自动化影视管理平台"
    else
        print_error "moviepilot"
    fi
}

deploy_iptv() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}iptv${RESET} 端口: ${GREEN}49101${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/iptv/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/iptv/docker-compose.yml << 'EOF'
services:
  iptv:
    image: ecnmcc/iptv
    container_name: iptv
    restart: unless-stopped
    ports:
      - "49101:81"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/iptv && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q iptv; then
        print_done "iptv"
        print_deploy_info "iptv" \
            "容器名称: ${GREEN}iptv${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49101${RESET}" \
            "描述: IPTV电视直播频道管理"
    else
        print_error "iptv"
    fi
}

deploy_homepage() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}homepage${RESET} 端口: ${GREEN}49102${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/homepage/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/homepage/docker-compose.yml << 'EOF'
services:
  homepage:
    image: ghcr.io/benphelps/homepage
    container_name: homepage
    restart: unless-stopped
    ports:
      - "49102:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/homepage && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q homepage; then
        print_done "homepage"
        print_deploy_info "homepage" \
            "容器名称: ${GREEN}homepage${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49102${RESET}" \
            "描述: 主页导航非常漂亮"
    else
        print_error "homepage"
    fi
}

deploy_homeassistant() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}homeassistant${RESET} 端口: ${GREEN}49103${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/homeassistant/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/homeassistant/docker-compose.yml << 'EOF'
services:
  homeassistant:
    image: homeassistant/home-assistant
    container_name: homeassistant
    restart: unless-stopped
    ports:
      - "49103:8123"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/homeassistant && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q homeassistant; then
        print_done "homeassistant"
        print_deploy_info "homeassistant" \
            "容器名称: ${GREEN}homeassistant${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49103${RESET}" \
            "描述: 全屋智能家居中枢"
    else
        print_error "homeassistant"
    fi
}

deploy_navidrome() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}navidrome${RESET} 端口: ${GREEN}49104${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/navidrome/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/navidrome/docker-compose.yml << 'EOF'
services:
  navidrome:
    image: navidrome/navidrome
    container_name: navidrome
    restart: unless-stopped
    ports:
      - "49104:4533"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/navidrome && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q navidrome; then
        print_done "navidrome"
        print_deploy_info "navidrome" \
            "容器名称: ${GREEN}navidrome${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49104${RESET}" \
            "描述: 个人音乐服务器"
    else
        print_error "navidrome"
    fi
}

deploy_moontv() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}moontv${RESET} 端口: ${GREEN}49105${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/moontv/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/moontv/docker-compose.yml << 'EOF'
services:
  moontv:
    image: godkp/moontv:latest
    container_name: moontv
    restart: unless-stopped
    ports:
      - "49105:10106"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/moontv && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q moontv; then
        print_done "moontv"
        print_deploy_info "moontv" \
            "容器名称: ${GREEN}moontv${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49105${RESET}" \
            "描述: 家庭顶流免费影音媒体"
    else
        print_error "moontv"
    fi
}

deploy_libretv() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}libretv${RESET} 端口: ${GREEN}49106${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/libretv/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/libretv/docker-compose.yml << 'EOF'
services:
  libretv:
    image: godkp/libretv:latest
    container_name: libretv
    restart: unless-stopped
    ports:
      - "49106:10500"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/libretv && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q libretv; then
        print_done "libretv"
        print_deploy_info "libretv" \
            "容器名称: ${GREEN}libretv${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49106${RESET}" \
            "描述: 全网顶流视频聚合网"
    else
        print_error "libretv"
    fi
}

deploy_emby() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}emby${RESET} 端口: ${GREEN}49107${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/emby/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/emby/docker-compose.yml << 'EOF'
services:
  emby:
    image: emby/embyserver
    container_name: emby
    restart: unless-stopped
    ports:
      - "49107:8096"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/emby && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q emby; then
        print_done "emby"
        print_deploy_info "emby" \
            "容器名称: ${GREEN}emby${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49107${RESET}" \
            "描述: 影音媒体服务器"
    else
        print_error "emby"
    fi
}

deploy_jellyfin() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}jellyfin${RESET} 端口: ${GREEN}49108${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/jellyfin/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/jellyfin/docker-compose.yml << 'EOF'
services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "49108:8096"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/jellyfin && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q jellyfin; then
        print_done "jellyfin"
        print_deploy_info "jellyfin" \
            "容器名称: ${GREEN}jellyfin${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49108${RESET}" \
            "描述: 影音媒体服务器"
    else
        print_error "jellyfin"
    fi
}

deploy_qbittorrent() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}qbittorrent${RESET} 端口: ${GREEN}49109${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/qbittorrent/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/qbittorrent/docker-compose.yml << 'EOF'
services:
  qbittorrent:
    image: linuxserver/qbittorrent
    container_name: qbittorrent
    restart: unless-stopped
    ports:
      - "49109:8080"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/qbittorrent && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q qbittorrent; then
        print_done "qbittorrent"
        print_deploy_info "qbittorrent" \
            "容器名称: ${GREEN}qbittorrent${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49109${RESET}" \
            "描述: BT下载神器"
    else
        print_error "qbittorrent"
    fi
}

deploy_transmission() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}transmission${RESET} 端口: ${GREEN}49110${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/transmission/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/transmission/docker-compose.yml << 'EOF'
services:
  transmission:
    image: linuxserver/transmission
    container_name: transmission
    restart: unless-stopped
    ports:
      - "49110:9091"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/transmission && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q transmission; then
        print_done "transmission"
        print_deploy_info "transmission" \
            "容器名称: ${GREEN}transmission${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49110${RESET}" \
            "描述: Download专用神器"
    else
        print_error "transmission"
    fi
}

deploy_synctv() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}synctv${RESET} 端口: ${GREEN}49111${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/synctv/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/synctv/docker-compose.yml << 'EOF'
services:
  synctv:
    image: stilleshan/synctv
    container_name: synctv
    restart: unless-stopped
    ports:
      - "49111:6677"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/synctv && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q synctv; then
        print_done "synctv"
        print_deploy_info "synctv" \
            "容器名称: ${GREEN}synctv${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49111${RESET}" \
            "描述: 和朋友一起看电影"
    else
        print_error "synctv"
    fi
}

deploy_openlist() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}openlist${RESET} 端口: ${GREEN}49112${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/openlist/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/openlist/docker-compose.yml << 'EOF'
services:
  openlist:
    image: alistorg/openlist
    container_name: openlist
    restart: unless-stopped
    ports:
      - "49112:5244"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/openlist && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q openlist; then
        print_done "openlist"
        print_deploy_info "openlist" \
            "容器名称: ${GREEN}openlist${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49112${RESET}" \
            "描述: 私人网络云盘"
    else
        print_error "openlist"
    fi
}

deploy_pansou() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}pansou${RESET} 端口: ${GREEN}49113${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/pansou/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/pansou/docker-compose.yml << 'EOF'
services:
  pansou:
    image: stilleshan/pansou
    container_name: pansou
    restart: unless-stopped
    ports:
      - "49113:8899"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/pansou && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q pansou; then
        print_done "pansou"
        print_deploy_info "pansou" \
            "容器名称: ${GREEN}pansou${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49113${RESET}" \
            "描述: 免费网盘资源搜索"
    else
        print_error "pansou"
    fi
}

deploy_komga() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}komga${RESET} 端口: ${GREEN}49114${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/komga/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/komga/docker-compose.yml << 'EOF'
services:
  komga:
    image: gotson/komga
    container_name: komga
    restart: unless-stopped
    ports:
      - "49114:25600"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/komga && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q komga; then
        print_done "komga"
        print_deploy_info "komga" \
            "容器名称: ${GREEN}komga${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49114${RESET}" \
            "描述: 漫画阅读器"
    else
        print_error "komga"
    fi
}

deploy_weizhi() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}weizhi${RESET} 端口: ${GREEN}49115${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/weizhi/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/weizhi/docker-compose.yml << 'EOF'
services:
  weizhi:
    image: ghcr.io/etwishcn/weizhi:latest
    container_name: weizhi
    restart: unless-stopped
    ports:
      - "49115:12345"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/weizhi && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q weizhi; then
        print_done "weizhi"
        print_deploy_info "weizhi" \
            "容器名称: ${GREEN}weizhi${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49115${RESET}" \
            "描述: 非常好用为知笔记"
    else
        print_error "weizhi"
    fi
}

deploy_ddnsgo() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}ddnsgo${RESET} 端口: ${GREEN}49116${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/ddnsgo/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/ddnsgo/docker-compose.yml << 'EOF'
services:
  ddnsgo:
    image: tothemoon/ddns-go
    container_name: ddnsgo
    restart: unless-stopped
    ports:
      - "49116:9876"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/ddnsgo && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q ddnsgo; then
        print_done "ddnsgo"
        print_deploy_info "ddnsgo" \
            "容器名称: ${GREEN}ddnsgo${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49116${RESET}" \
            "描述: 动态域名解析"
    else
        print_error "ddnsgo"
    fi
}

deploy_panel() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}panel${RESET} 端口: ${GREEN}49117${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/panel/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/panel/docker-compose.yml << 'EOF'
services:
  panel:
    image: filegang/panel
    container_name: panel
    restart: unless-stopped
    ports:
      - "49117:20000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/panel && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q panel; then
        print_done "panel"
        print_deploy_info "panel" \
            "容器名称: ${GREEN}panel${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49117${RESET}" \
            "描述: docker导航页面"
    else
        print_error "panel"
    fi
}

deploy_drawio() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}drawio${RESET} 端口: ${GREEN}49118${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/drawio/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/drawio/docker-compose.yml << 'EOF'
services:
  drawio:
    image: fjudith/drawio
    container_name: drawio
    restart: unless-stopped
    ports:
      - "49118:8080"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/drawio && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q drawio; then
        print_done "drawio"
        print_deploy_info "drawio" \
            "容器名称: ${GREEN}drawio${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49118${RESET}" \
            "描述: 网页绘图工具"
    else
        print_error "drawio"
    fi
}

deploy_qinglong() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}qinglong${RESET} 端口: ${GREEN}49119${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/qinglong/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/qinglong/docker-compose.yml << 'EOF'
services:
  qinglong:
    image: whyour/qinglong
    container_name: qinglong
    restart: unless-stopped
    ports:
      - "49119:5700"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/qinglong && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q qinglong; then
        print_done "qinglong"
        print_deploy_info "qinglong" \
            "容器名称: ${GREEN}qinglong${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49119${RESET}" \
            "描述: 青龙面板自动化"
    else
        print_error "qinglong"
    fi
}

deploy_sonarr() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}sonarr${RESET} 端口: ${GREEN}49120${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/sonarr/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/sonarr/docker-compose.yml << 'EOF'
services:
  sonarr:
    image: linuxserver/sonarr
    container_name: sonarr
    restart: unless-stopped
    ports:
      - "49120:8989"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/sonarr && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q sonarr; then
        print_done "sonarr"
        print_deploy_info "sonarr" \
            "容器名称: ${GREEN}sonarr${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49120${RESET}" \
            "描述: 自动追剧追番"
    else
        print_error "sonarr"
    fi
}

deploy_newsnow() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}newsnow${RESET} 端口: ${GREEN}49121${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/newsnow/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/newsnow/docker-compose.yml << 'EOF'
services:
  newsnow:
    image: benbusby/newsnow
    container_name: newsnow
    restart: unless-stopped
    ports:
      - "49121:4000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/newsnow && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q newsnow; then
        print_done "newsnow"
        print_deploy_info "newsnow" \
            "容器名称: ${GREEN}newsnow${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49121${RESET}" \
            "描述: 实时新闻聚合阅读"
    else
        print_error "newsnow"
    fi
}

deploy_prowlarr() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}prowlarr${RESET} 端口: ${GREEN}49122${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/prowlarr/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/prowlarr/docker-compose.yml << 'EOF'
services:
  prowlarr:
    image: linuxserver/prowlarr
    container_name: prowlarr
    restart: unless-stopped
    ports:
      - "49122:9696"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/prowlarr && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q prowlarr; then
        print_done "prowlarr"
        print_deploy_info "prowlarr" \
            "容器名称: ${GREEN}prowlarr${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49122${RESET}" \
            "描述: 影视资源索引器"
    else
        print_error "prowlarr"
    fi
}

deploy_radarr() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}radarr${RESET} 端口: ${GREEN}49123${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/radarr/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/radarr/docker-compose.yml << 'EOF'
services:
  radarr:
    image: linuxserver/radarr
    container_name: radarr
    restart: unless-stopped
    ports:
      - "49123:7878"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/radarr && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q radarr; then
        print_done "radarr"
        print_deploy_info "radarr" \
            "容器名称: ${GREEN}radarr${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49123${RESET}" \
            "描述: 电影资源刮削封面"
    else
        print_error "radarr"
    fi
}

deploy_suwayomi() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}suwayomi${RESET} 端口: ${GREEN}49124${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/suwayomi/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/suwayomi/docker-compose.yml << 'EOF'
services:
  suwayomi:
    image: suwayomi/suwayomi
    container_name: suwayomi
    restart: unless-stopped
    ports:
      - "49124:4567"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/suwayomi && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q suwayomi; then
        print_done "suwayomi"
        print_deploy_info "suwayomi" \
            "容器名称: ${GREEN}suwayomi${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49124${RESET}" \
            "描述: 免费漫画在线阅读"
    else
        print_error "suwayomi"
    fi
}

deploy_reader() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}reader${RESET} 端口: ${GREEN}49125${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/reader/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/reader/docker-compose.yml << 'EOF'
services:
  reader:
    image: rankesi/reader
    container_name: reader
    restart: unless-stopped
    ports:
      - "49125:8899"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/reader && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q reader; then
        print_done "reader"
        print_deploy_info "reader" \
            "容器名称: ${GREEN}reader${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49125${RESET}" \
            "描述: 手机免费小说阅读"
    else
        print_error "reader"
    fi
}

deploy_solara() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}solara${RESET} 端口: ${GREEN}49126${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/solara/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/solara/docker-compose.yml << 'EOF'
services:
  solara:
    image: sswrdr/solara
    container_name: solara
    restart: unless-stopped
    ports:
      - "49126:8000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/solara && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q solara; then
        print_done "solara"
        print_deploy_info "solara" \
            "容器名称: ${GREEN}solara${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49126${RESET}" \
            "描述: 免费无损音乐下载"
    else
        print_error "solara"
    fi
}

deploy_hongjing() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}hongjing${RESET} 端口: ${GREEN}49127${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/hongjing/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/hongjing/docker-compose.yml << 'EOF'
services:
  hongjing:
    image: sswrdr/hongjing
    container_name: hongjing
    restart: unless-stopped
    ports:
      - "49127:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/hongjing && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q hongjing; then
        print_done "hongjing"
        print_deploy_info "hongjing" \
            "容器名称: ${GREEN}hongjing${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49127${RESET}" \
            "描述: 红色警戒网页版X86"
    else
        print_error "hongjing"
    fi
}

deploy_rustpad() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}rustpad${RESET} 端口: ${GREEN}49128${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/rustpad/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/rustpad/docker-compose.yml << 'EOF'
services:
  rustpad:
    image: ekzhang/rustpad
    container_name: rustpad
    restart: unless-stopped
    ports:
      - "49128:8080"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/rustpad && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q rustpad; then
        print_done "rustpad"
        print_deploy_info "rustpad" \
            "容器名称: ${GREEN}rustpad${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49128${RESET}" \
            "描述: 协同文本编辑器"
    else
        print_error "rustpad"
    fi
}

deploy_contra() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}contra${RESET} 端口: ${GREEN}49129${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/contra/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/contra/docker-compose.yml << 'EOF'
services:
  contra:
    image: sswrdr/contra
    container_name: contra
    restart: unless-stopped
    ports:
      - "49129:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/contra && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q contra; then
        print_done "contra"
        print_deploy_info "contra" \
            "容器名称: ${GREEN}contra${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49129${RESET}" \
            "描述: 魂斗罗网页版X86"
    else
        print_error "contra"
    fi
}

deploy_feiji() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}feiji${RESET} 端口: ${GREEN}49130${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/feiji/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/feiji/docker-compose.yml << 'EOF'
services:
  feiji:
    image: sswrdr/feiji
    container_name: feiji
    restart: unless-stopped
    ports:
      - "49130:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/feiji && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q feiji; then
        print_done "feiji"
        print_deploy_info "feiji" \
            "容器名称: ${GREEN}feiji${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49130${RESET}" \
            "描述: 疯狂飞机网页版X86"
    else
        print_error "feiji"
    fi
}

deploy_katelyatv() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}katelyatv${RESET} 端口: ${GREEN}49131${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/katelyatv/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/katelyatv/docker-compose.yml << 'EOF'
services:
  katelyatv:
    image: katelyatv/katelyatv
    container_name: katelyatv
    restart: unless-stopped
    ports:
      - "49131:8096"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/katelyatv && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q katelyatv; then
        print_done "katelyatv"
        print_deploy_info "katelyatv" \
            "容器名称: ${GREEN}katelyatv${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49131${RESET}" \
            "描述: 超多影视聚合在线播放"
    else
        print_error "katelyatv"
    fi
}

deploy_playlistdl() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}playlistdl${RESET} 端口: ${GREEN}49132${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/playlistdl/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/playlistdl/docker-compose.yml << 'EOF'
services:
  playlistdl:
    image: sswrdr/playlistdl
    container_name: playlistdl
    restart: unless-stopped
    ports:
      - "49132:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/playlistdl && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q playlistdl; then
        print_done "playlistdl"
        print_deploy_info "playlistdl" \
            "容器名称: ${GREEN}playlistdl${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49132${RESET}" \
            "描述: 超好用音乐下载工具"
    else
        print_error "playlistdl"
    fi
}

deploy_anime() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}anime${RESET} 端口: ${GREEN}49133${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/anime/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/anime/docker-compose.yml << 'EOF'
services:
  anime:
    image: remotelystream/animedl
    container_name: anime
    restart: unless-stopped
    ports:
      - "49133:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/anime && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q anime; then
        print_done "anime"
        print_deploy_info "anime" \
            "容器名称: ${GREEN}anime${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49133${RESET}" \
            "描述: 全自动下载看动漫追番"
    else
        print_error "anime"
    fi
}

deploy_omnibox() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}omnibox${RESET} 端口: ${GREEN}49134${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/omnibox/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/omnibox/docker-compose.yml << 'EOF'
services:
  omnibox:
    image: sswrdr/omnibox
    container_name: omnibox
    restart: unless-stopped
    ports:
      - "49134:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/omnibox && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q omnibox; then
        print_done "omnibox"
        print_deploy_info "omnibox" \
            "容器名称: ${GREEN}omnibox${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49134${RESET}" \
            "描述: 全自动看电影网盘整合"
    else
        print_error "omnibox"
    fi
}

deploy_smartstrm() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}smartstrm${RESET} 端口: ${GREEN}49135${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/smartstrm/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/smartstrm/docker-compose.yml << 'EOF'
services:
  smartstrm:
    image: smartstrm/smartstrm
    container_name: smartstrm
    restart: unless-stopped
    ports:
      - "49135:8080"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/smartstrm && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q smartstrm; then
        print_done "smartstrm"
        print_deploy_info "smartstrm" \
            "容器名称: ${GREEN}smartstrm${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49135${RESET}" \
            "描述: STRM全自动生成工具"
    else
        print_error "smartstrm"
    fi
}

deploy_convertx() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}convertx${RESET} 端口: ${GREEN}49136${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/convertx/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/convertx/docker-compose.yml << 'EOF'
services:
  convertx:
    image: sswrdr/convertx
    container_name: convertx
    restart: unless-stopped
    ports:
      - "49136:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/convertx && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q convertx; then
        print_done "convertx"
        print_deploy_info "convertx" \
            "容器名称: ${GREEN}convertx${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49136${RESET}" \
            "描述: 超级格式转换工具"
    else
        print_error "convertx"
    fi
}

deploy_paintboard() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}paintboard${RESET} 端口: ${GREEN}49137${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/paintboard/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/paintboard/docker-compose.yml << 'EOF'
services:
  paintboard:
    image: stilleshan/paintboard
    container_name: paintboard
    restart: unless-stopped
    ports:
      - "49137:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/paintboard && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q paintboard; then
        print_done "paintboard"
        print_deploy_info "paintboard" \
            "容器名称: ${GREEN}paintboard${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49137${RESET}" \
            "描述: 非常好用的在线画板"
    else
        print_error "paintboard"
    fi
}

deploy_icons() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}icons${RESET} 端口: ${GREEN}49138${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/icons/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/icons/docker-compose.yml << 'EOF'
services:
  icons:
    image: macewan/icons
    container_name: icons
    restart: unless-stopped
    ports:
      - "49138:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/icons && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q icons; then
        print_done "icons"
        print_deploy_info "icons" \
            "容器名称: ${GREEN}icons${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49138${RESET}" \
            "描述: 私人专用图标库"
    else
        print_error "icons"
    fi
}

deploy_minipaint() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}minipaint${RESET} 端口: ${GREEN}49139${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/minipaint/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/minipaint/docker-compose.yml << 'EOF'
services:
  minipaint:
    image: timgabea/minipaint
    container_name: minipaint
    restart: unless-stopped
    ports:
      - "49139:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/minipaint && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q minipaint; then
        print_done "minipaint"
        print_deploy_info "minipaint" \
            "容器名称: ${GREEN}minipaint${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49139${RESET}" \
            "描述: 强大的在线修图工具"
    else
        print_error "minipaint"
    fi
}

deploy_panhub() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}panhub${RESET} 端口: ${GREEN}49140${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/panhub/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/panhub/docker-compose.yml << 'EOF'
services:
  panhub:
    image: stilleshan/panhub
    container_name: panhub
    restart: unless-stopped
    ports:
      - "49140:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/panhub && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q panhub; then
        print_done "panhub"
        print_deploy_info "panhub" \
            "容器名称: ${GREEN}panhub${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49140${RESET}" \
            "描述: 网盘资源搜索工具"
    else
        print_error "panhub"
    fi
}

deploy_audiobooks() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}audiobooks${RESET} 端口: ${GREEN}49141${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/audiobooks/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/audiobooks/docker-compose.yml << 'EOF'
services:
  audiobooks:
    image: towerwatch/audiobooks
    container_name: audiobooks
    restart: unless-stopped
    ports:
      - "49141:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/audiobooks && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q audiobooks; then
        print_done "audiobooks"
        print_deploy_info "audiobooks" \
            "容器名称: ${GREEN}audiobooks${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49141${RESET}" \
            "描述: 有声图书管理工具"
    else
        print_error "audiobooks"
    fi
}

deploy_xiaoaimusic() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}xiaoaimusic${RESET} 端口: ${GREEN}49142${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/xiaoaimusic/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/xiaoaimusic/docker-compose.yml << 'EOF'
services:
  xiaoaimusic:
    image: sswrdr/xiaoaimusic
    container_name: xiaoaimusic
    restart: unless-stopped
    ports:
      - "49142:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/xiaoaimusic && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q xiaoaimusic; then
        print_done "xiaoaimusic"
        print_deploy_info "xiaoaimusic" \
            "容器名称: ${GREEN}xiaoaimusic${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49142${RESET}" \
            "描述: 小爱音箱播放器"
    else
        print_error "xiaoaimusic"
    fi
}

deploy_cloudsaver() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}cloudsaver${RESET} 端口: ${GREEN}49143${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/cloudsaver/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/cloudsaver/docker-compose.yml << 'EOF'
services:
  cloudsaver:
    image: stilleshan/cloudsaver
    container_name: cloudsaver
    restart: unless-stopped
    ports:
      - "49143:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/cloudsaver && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q cloudsaver; then
        print_done "cloudsaver"
        print_deploy_info "cloudsaver" \
            "容器名称: ${GREEN}cloudsaver${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49143${RESET}" \
            "描述: 网盘资源自动转存"
    else
        print_error "cloudsaver"
    fi
}

deploy_ipttv() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}ipttv${RESET} 端口: ${GREEN}49144${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/ipttv/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/ipttv/docker-compose.yml << 'EOF'
services:
  ipttv:
    image: ecnmcc/ipttv
    container_name: ipttv
    restart: unless-stopped
    ports:
      - "49144:81"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/ipttv && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q ipttv; then
        print_done "ipttv"
        print_deploy_info "ipttv" \
            "容器名称: ${GREEN}ipttv${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49144${RESET}" \
            "描述: 全自动维护IPTV直播源"
    else
        print_error "ipttv"
    fi
}

deploy_zfile() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}zfile${RESET} 端口: ${GREEN}49145${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/zfile/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/zfile/docker-compose.yml << 'EOF'
services:
  zfile:
    image: zfile
    container_name: zfile
    restart: unless-stopped
    ports:
      - "49145:8080"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/zfile && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q zfile; then
        print_done "zfile"
        print_deploy_info "zfile" \
            "容器名称: ${GREEN}zfile${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49145${RESET}" \
            "描述: 私人网盘管理"
    else
        print_error "zfile"
    fi
}

deploy_halo() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}halo${RESET} 端口: ${GREEN}49146${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/halo/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/halo/docker-compose.yml << 'EOF'
services:
  halo:
    image: halohub/halo
    container_name: halo
    restart: unless-stopped
    ports:
      - "49146:8090"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/halo && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q halo; then
        print_done "halo"
        print_deploy_info "halo" \
            "容器名称: ${GREEN}halo${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49146${RESET}" \
            "描述: 最炫酷私人博客"
    else
        print_error "halo"
    fi
}

deploy_ezbookkeeping() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}ezbookkeeping${RESET} 端口: ${GREEN}49147${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/ezbookkeeping/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/ezbookkeeping/docker-compose.yml << 'EOF'
services:
  ezbookkeeping:
    image: sswrdr/ezbookkeeping
    container_name: ezbookkeeping
    restart: unless-stopped
    ports:
      - "49147:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/ezbookkeeping && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q ezbookkeeping; then
        print_done "ezbookkeeping"
        print_deploy_info "ezbookkeeping" \
            "容器名称: ${GREEN}ezbookkeeping${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49147${RESET}" \
            "描述: 家庭记账管理工具"
    else
        print_error "ezbookkeeping"
    fi
}

deploy_simplemindmap() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}simplemindmap${RESET} 端口: ${GREEN}49148${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/simplemindmap/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/simplemindmap/docker-compose.yml << 'EOF'
services:
  simplemindmap:
    image: sswrdr/simplemindmap
    container_name: simplemindmap
    restart: unless-stopped
    ports:
      - "49148:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/simplemindmap && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q simplemindmap; then
        print_done "simplemindmap"
        print_deploy_info "simplemindmap" \
            "容器名称: ${GREEN}simplemindmap${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49148${RESET}" \
            "描述: 在线制作思维导图"
    else
        print_error "simplemindmap"
    fi
}

deploy_hivision() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}hivision${RESET} 端口: ${GREEN}49149${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/hivision/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/hivision/docker-compose.yml << 'EOF'
services:
  hivision:
    image: shadow0039/hivision
    container_name: hivision
    restart: unless-stopped
    ports:
      - "49149:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/hivision && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q hivision; then
        print_done "hivision"
        print_deploy_info "hivision" \
            "容器名称: ${GREEN}hivision${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49149${RESET}" \
            "描述: 一键生成证件照"
    else
        print_error "hivision"
    fi
}

deploy_homarr() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}homarr${RESET} 端口: ${GREEN}49150${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/homarr/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/homarr/docker-compose.yml << 'EOF'
services:
  homarr:
    image: ghcr.io/benphelps/homepage
    container_name: homarr
    restart: unless-stopped
    ports:
      - "49150:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/homarr && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q homarr; then
        print_done "homarr"
        print_deploy_info "homarr" \
            "容器名称: ${GREEN}homarr${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49150${RESET}" \
            "描述: 非常简洁的页面导航"
    else
        print_error "homarr"
    fi
}

deploy_talebook() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}talebook${RESET} 端口: ${GREEN}49151${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/talebook/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/talebook/docker-compose.yml << 'EOF'
services:
  talebook:
    image: talebook/talebook
    container_name: talebook
    restart: unless-stopped
    ports:
      - "49151:1234"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/talebook && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q talebook; then
        print_done "talebook"
        print_deploy_info "talebook" \
            "容器名称: ${GREEN}talebook${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49151${RESET}" \
            "描述: 私人图书馆"
    else
        print_error "talebook"
    fi
}

deploy_memos() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}memos${RESET} 端口: ${GREEN}49152${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/memos/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/memos/docker-compose.yml << 'EOF'
services:
  memos:
    image: neosmemos/memos
    container_name: memos
    restart: unless-stopped
    ports:
      - "49152:5230"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/memos && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q memos; then
        print_done "memos"
        print_deploy_info "memos" \
            "容器名称: ${GREEN}memos${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49152${RESET}" \
            "描述: 强大的个人备忘录"
    else
        print_error "memos"
    fi
}

deploy_bentopdf() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}bentopdf${RESET} 端口: ${GREEN}49153${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/bentopdf/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/bentopdf/docker-compose.yml << 'EOF'
services:
  bentopdf:
    image: bento/bentopdf
    container_name: bentopdf
    restart: unless-stopped
    ports:
      - "49153:3000"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/bentopdf && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q bentopdf; then
        print_done "bentopdf"
        print_deploy_info "bentopdf" \
            "容器名称: ${GREEN}bentopdf${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49153${RESET}" \
            "描述: 私人PDF工具箱"
    else
        print_error "bentopdf"
    fi
}

deploy_nextcloud() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BOLD}正在部署: ${YELLOW}nextcloud${RESET} 端口: ${GREEN}49154${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    draw_progress 1 4 "正在创建配置目录..."
    sudo mkdir -p ${BASE_DIR}/nextcloud/config
    draw_progress 2 4 "正在创建 docker-compose.yml..."
    cat > ${BASE_DIR}/nextcloud/docker-compose.yml << 'EOF'
services:
  nextcloud:
    image: nextcloud
    container_name: nextcloud
    restart: unless-stopped
    ports:
      - "49154:8080"
    volumes:
      - ./config:/config
EOF
    draw_progress 3 4 "正在拉取镜像..."
    cd ${BASE_DIR}/nextcloud && sudo docker compose pull
    draw_progress 4 4 "正在启动容器..."
    sudo docker compose up -d
    sleep 3
    if sudo docker ps | grep -q nextcloud; then
        print_done "nextcloud"
        print_deploy_info "nextcloud" \
            "容器名称: ${GREEN}nextcloud${RESET}" \
            "访问地址: ${GREEN}http://$(hostname -I | awk '{print $1}'):49154${RESET}" \
            "描述: WPS远程协作"
    else
        print_error "nextcloud"
    fi
}

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
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [ N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "27" "panel" "59" "hivision"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "28" "drawio" "60" "homarr"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "29" "qinglong" "61" "talebook"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "30" "sonarr" "62" "memos"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "31" "newsnow" "63" "bentopdf"
    printf "${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET} [N] ${BOLD}%-3s${RESET} ${GREEN}%-24s${RESET} ${CYAN}│${RESET}\n" "32" "prowlarr" "64" "nextcloud"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "${CYAN}提示:${RESET} 输入 ${YELLOW}1 3 5${RESET} 即可同时部署，输入 ${YELLOW}b${RESET} 退出脚本"
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
            b|B) echo -e "${YELLOW}退出脚本，再见！${RESET}"; exit 0 ;;
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
            17) deploy_emby ;;
            18) deploy_jellyfin ;;
            19) deploy_qbittorrent ;;
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
            64) deploy_nextcloud ;;            *) echo -e "${RED}警告: 无效编号 '$choice' 已跳过${RESET}" ;;
        esac
    done

    echo -e "${GREEN}所有选定任务处理完毕！${RESET}"
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
