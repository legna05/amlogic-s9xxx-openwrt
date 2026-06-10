#!/bin/bash

FEEDS_PATH=""
if [ -f "./feeds.conf.default" ]; then
    # feeds.conf.default存在（无论feeds.conf是否存在都选它）
    FEEDS_PATH="./feeds.conf.default"
elif [ -f "./feeds.conf" ]; then
    # feeds.conf.default不存在但feeds.conf存在
    FEEDS_PATH="./feeds.conf"
else
    # 两个都不存在
    echo "Warning: No feeds configuration file found"
    exit 1
fi

echo "FEEDS_PATH=$FEEDS_PATH"

sed -i '/^#/d' "$FEEDS_PATH"
sed -i '/packages_ext/d' "$FEEDS_PATH"

# 定义要添加的源列表（格式："关键字 源名称 源地址;分支"）
repos=(
    "passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main"
    "passwall_luci     https://github.com/Openwrt-Passwall/openwrt-passwall.git;main"
    "openclash         https://github.com/vernesong/OpenClash.git;master"
    "nikki             https://github.com/nikkinikki-org/OpenWrt-nikki.git;main"
    "gecoosac          https://github.com/laipeng668/luci-app-gecoosac.git;main"
    "ddns_go           https://github.com/sirpdboy/luci-app-ddns-go.git;main"
    "socat             https://github.com/chenmozhijin/luci-app-socat.git;main"
)

# 批量添加
for repo in "${repos[@]}"; do
    name="${repo%% *}"          # 提取关键字（第一个空格前的内容）
    url="${repo#* }"             # 提取完整URL
    if ! grep -q "$name" "$FEEDS_PATH"; then
        [ -n "$(tail -c 1 "$FEEDS_PATH")" ] && echo "" >> "$FEEDS_PATH"
        echo "src-git $name $url" >> "$FEEDS_PATH"
        echo "已添加: $name"
    else
        echo "已存在: $name，跳过"
    fi
done


