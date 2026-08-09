#!/bin/bash
# ============================================================================
# OpenWrt 构建前准备脚本（优化版）
# 功能：替换 Golang、安装额外包、修改主题、集成 TurboACC 和 SmartDNS 等
# ============================================================================

set -e  # 遇到错误立即退出，避免后续依赖缺失

# --------------------------------- 工具函数 ---------------------------------
# 带颜色的打印（可选）
info() {
    echo -e "\033[32m[INFO]\033[0m $*"
}

warn() {
    echo -e "\033[33m[WARN]\033[0m $*"
}

error() {
    echo -e "\033[31m[ERROR]\033[0m $*" >&2
}

success() {
    echo -e "\033[36m[SUCCESS]\033[0m $*"
}

# 开始一个功能块
section_start() {
    echo ""
    echo "============================================================"
    info "开始执行: $1"
    echo "============================================================"
}

section_end() {
    success "完成: $1"
    echo "============================================================"
    echo ""
}

# --------------------------------- 功能函数 ---------------------------------

# 1. 添加自定义 config（追加 GENERAL.txt 到 .config）
setup_config() {
    section_start "添加自定义配置"
    local script_path
    script_path="$(cd "$(dirname "$0")/" && pwd)"
    echo "SCRIPT_PATH=$script_path"

    if [[ -f "$script_path/GENERAL.txt" ]]; then
        cat "$script_path/GENERAL.txt" >> .config
        info "已追加 GENERAL.txt 到 .config"
        tail -n 10 .config
    else
        warn "未找到 GENERAL.txt，跳过"
    fi
    section_end "添加自定义配置"
}

# 2. 替换 Golang 包（删除旧目录，克隆新分支）
replace_golang() {
    section_start "替换 Golang 包"
    local golang_dir="./feeds/packages/lang/golang"
    echo "GOLANG_DIR=$golang_dir"

    if [[ -d "$golang_dir" ]]; then
        info "发现已存在的 golang 目录，正在删除..."
        rm -rf "$golang_dir"
        if [[ $? -eq 0 ]]; then
            success "目录删除成功"
        else
            error "目录删除失败，可能权限不足"
            exit 1
        fi
    else
        info "golang 目录不存在，无需删除"
    fi

    info "正在克隆 golang 包到: $golang_dir"
    git clone https://github.com/sbwml/packages_lang_golang -b 26.x "$golang_dir"
    if [[ $? -eq 0 ]]; then
        success "golang 包替换成功！"
        ls -la "$golang_dir"
    else
        error "golang 包替换失败，请检查网络或仓库地址"
        exit 1
    fi
    section_end "替换 Golang 包"
}

# 3. TTYD 免登录
patch_ttyd() {
    section_start "TTYD 免登录配置"
    local ttyd_config="./feeds/packages/utils/ttyd/files/ttyd.config"
    if [[ -f "$ttyd_config" ]]; then
        sed -i 's|/bin/login|/bin/login -f root|g' "$ttyd_config"
        success "TTYD 免登录已启用"
    else
        warn "ttyd.config 不存在，跳过"
    fi
    section_end "TTYD 免登录配置"
}

# 4. 安装 netspeedtest（从 muink 仓库克隆）
install_netspeedtest() {
    section_start "安装 netspeedtest"
    local netspeedtest_path="./package/luci-app-netspeedtest"
    git clone --depth 1 --branch master --single-branch --no-checkout \
        https://github.com/muink/luci-app-netspeedtest.git "$netspeedtest_path"
    pushd "$netspeedtest_path" > /dev/null
    umask 022
    git checkout
    popd > /dev/null
    success "netspeedtest 安装完成"
    section_end "安装 netspeedtest"
}

# 5. 安装 diskman（下载 Makefile）
install_diskman() {
    section_start "安装 diskman"
    local package_path="./package"
    mkdir -p "$package_path/luci-app-diskman"
    wget -q https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile \
        -O "$package_path/luci-app-diskman/Makefile"
    mkdir -p "$package_path/parted"
    wget -q https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile \
        -O "$package_path/parted/Makefile"
    success "diskman 安装完成"
    section_end "安装 diskman"
}

# 6. 修改默认主题为 argon
set_default_theme() {
    section_start "修改默认主题为 luci-theme-argon"
    find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' {} \;
    success "默认主题已修改为 argon"
    section_end "修改默认主题"
}

# 7. 配置 argon 主题（字体、颜色等）
configure_argon() {
    section_start "配置 argon 主题"
    local argon_config="./feeds/theme_argon/luci-app-argon-config/root/etc/config/argon"
    if [[ -f "$argon_config" ]]; then
        sed -i "s/primary '.*'/primary '#e198b4'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" "$argon_config"
        success "argon 主题配置已更新"
    else
        warn "argon 配置文件不存在，跳过"
    fi
    section_end "配置 argon 主题"
}

# 8. 添加 TurboACC（下载并执行外部脚本）
add_turboacc() {
    section_start "添加 TurboACC"
    curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh
    if [[ -f add_turboacc.sh ]]; then
        bash add_turboacc.sh
        success "TurboACC 添加完成"
        rm -f add_turboacc.sh
    else
        error "下载 add_turboacc.sh 失败"
        exit 1
    fi
    section_end "添加 TurboACC"
}

# 9. 安装 SmartDNS（下载并解压）
install_smartdns() {
    section_start "安装 SmartDNS"
    local WORKINGDIR="./feeds/packages/net/smartdns"
    mkdir -p "$WORKINGDIR"
    rm -rf "$WORKINGDIR"/*

    wget -q https://github.com/pymumu/openwrt-smartdns/archive/master.zip -O "$WORKINGDIR/master.zip"
    unzip -q "$WORKINGDIR/master.zip" -d "$WORKINGDIR"
    mv "$WORKINGDIR/openwrt-smartdns-master/"* "$WORKINGDIR/"
    rmdir "$WORKINGDIR/openwrt-smartdns-master"
    rm "$WORKINGDIR/master.zip"
    sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/' "$WORKINGDIR"/Makefile
    cat "$WORKINGDIR"/Makefile | grep PKG_MIRROR_HASH

    local LUCIBRANCH="master"
    local LUCI_WD="./feeds/luci/applications/luci-app-smartdns"
    mkdir -p "$LUCI_WD"
    rm -rf "$LUCI_WD"/*

    wget -q "https://github.com/pymumu/luci-app-smartdns/archive/${LUCIBRANCH}.zip" -O "$LUCI_WD/${LUCIBRANCH}.zip"
    unzip -q "$LUCI_WD/${LUCIBRANCH}.zip" -d "$LUCI_WD"
    mv "$LUCI_WD/luci-app-smartdns-${LUCIBRANCH}/"* "$LUCI_WD/"
    rmdir "$LUCI_WD/luci-app-smartdns-${LUCIBRANCH}"
    rm "$LUCI_WD/${LUCIBRANCH}.zip"

    success "SmartDNS 安装完成"
    section_end "安装 SmartDNS"
}

mosdns_feeds() {
    # remove v2ray-geodata package from feeds
    rm -rf feeds/packages/net/v2ray-geodata

    git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
    git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
}

# 10. 安装 feeds（必须放在最后）
install_feeds() {
    section_start "安装 feeds"
    ./scripts/feeds install -a
    success "feeds 安装完成"
    section_end "安装 feeds"
}

# --------------------------------- 主执行流程 ---------------------------------
main() {
    info "========== OpenWrt 构建预处理开始 =========="
    setup_config
    replace_golang
    patch_ttyd
    install_netspeedtest
    install_diskman
    set_default_theme
    configure_argon
    add_turboacc
    install_smartdns
    mosdns_feeds
    install_feeds
    info "========== 所有预处理步骤成功完成 =========="
}

# 执行主函数
main