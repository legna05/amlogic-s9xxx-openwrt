#!/bin/bash

# 获取脚本所在目录
SCRIPT_PATH="$(cd "$(dirname "$0")/" && pwd)"
echo "SCRIPT_PATH=$SCRIPT_PATH"

# 自定义config
cat $SCRIPT_PATH/GENERAL.txt >> .config
tail -n 10 ./config

# 设置目标目录（默认位置）
GOLANG_DIR="./feeds/packages/lang/golang"
echo "GOLANG_DIR=$GOLANG_DIR"

# 检查目录是否存在，如果存在则删除
if [ -d "$GOLANG_DIR" ]; then
    echo "发现已存在的golang目录，正在删除..."
    rm -rf "$GOLANG_DIR"

    # 检查删除是否成功
    if [ $? -eq 0 ]; then
        echo "✓ 目录删除成功"
    else
        echo "✗ 目录删除失败，可能权限不足"
        exit 1
    fi
else
    echo "golang目录不存在，无需删除"
fi

# 克隆新的golang包
echo "正在克隆golang包到: $GOLANG_DIR"
git clone https://github.com/sbwml/packages_lang_golang -b 26.x "$GOLANG_DIR"

# 检查克隆是否成功
if [ $? -eq 0 ]; then
    echo "golang包替换成功！"

    # 显示克隆后的目录结构
    echo "克隆完成后的目录："
    ls -la "$GOLANG_DIR"
else
    echo "golang包替换失败，请检查网络或仓库地址"
    exit 1
fi

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' ./feeds/packages/utils/ttyd/files/ttyd.config

# netspeedtest
netspeedtest_path="./package/luci-app-netspeedtest"
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/luci-app-netspeedtest.git $netspeedtest_path
pushd $netspeedtest_path
umask 022
git checkout
popd

# 定义目标文件路径（修改为实际路径）
package_path="./package"

# diskman安装
mkdir -p $package_path/luci-app-diskman
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O $package_path/luci-app-diskman/Makefile
mkdir -p $package_path/parted
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O $package_path/parted/Makefile

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")