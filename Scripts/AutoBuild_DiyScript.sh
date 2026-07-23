#!/bin/bash
# AutoBuild Module by Hyy2001 <https://github.com/Hyy2001X/AutoBuild-Actions-BETA>
# AutoBuild DiyScript

Firmware_Diy_Core() {

	Author=AUTO
	# 作者名称, AUTO: [自动识别]
	Author_URL=AUTO
	# 自定义作者网站或域名, AUTO: [自动识别]
	Default_Flag=AUTO
	# 固件标签 (名称后缀), 适用不同配置文件, AUTO: [自动识别]
	Default_IP="192.168.1.1"
	# 固件 IP 地址
	Default_Title="Powered by AutoBuild-Actions"
	# 固件终端首页显示的额外信息
	
	Short_Fw_Date=true
	# 简短的固件日期, true: [20210601]; false: [202106012359]
	x86_Full_Images=false
	# 额外上传已检测到的 x86 虚拟磁盘镜像, true: [上传]; false: [不上传]
	Fw_MFormat=AUTO
	# 自定义固件格式, AUTO: [自动识别]
	Regex_Skip="packages|buildinfo|sha256sums|manifest|kernel|rootfs|factory|itb|profile|ext4|json"
	# 输出固件时丢弃包含该内容的固件/文件
	AutoBuild_Features=true
	# 添加 AutoBuild 固件特性, true: [开启]; false: [关闭]
	
	AutoBuild_Features_Patch=false
	AutoBuild_Features_Kconfig=false
}

Firmware_Diy() {

	# 请在该函数内定制固件

	# 可用预设变量, 其他可用变量请参考运行日志
	# ${OP_AUTHOR}			OpenWrt 源码作者
	# ${OP_REPO}				OpenWrt 仓库名称
	# ${OP_BRANCH}			OpenWrt 源码分支
	# ${TARGET_PROFILE}		设备名称
	# ${TARGET_BOARD}			设备架构
	# ${TARGET_FLAG}			固件名称后缀

	# ${WORK}				OpenWrt 源码位置
	# ${CONFIG_FILE}			使用的配置文件名称
	# ${FEEDS_CONF}			OpenWrt 源码目录下的 feeds.conf.default 文件
	# ${CustomFiles}			仓库中的 /CustomFiles 绝对路径
	# ${Scripts}				仓库中的 /Scripts 绝对路径
	# ${FEEDS_LUCI}			OpenWrt 源码目录下的 package/feeds/luci 目录
	# ${FEEDS_PKG}			OpenWrt 源码目录下的 package/feeds/packages 目录
	# ${BASE_FILES}			OpenWrt 源码目录下的 package/base-files/files 目录

	:
}

echo "开始 DIY 配置..."
echo "===================="

# Git稀疏克隆，只克隆指定目录到本地
# 参数1是分支名, 参数2是仓库地址, 参数3是子目录，同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

#替换 golang 版本
rm -rf feeds/packages/lang/golang
rm -rf feeds/luci/applications/luci-app-netdata
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
git clone https://github.com/AdguardTeam/AdGuardHome package/AdGuardHome

./scripts/feeds update -a
./scripts/feeds install -a

#内置X86-clash内核
mkdir -p files/etc/openclash/core
wget -qO- https://github.com/vernesong/OpenClash/raw/core/master/meta/clash-linux-amd64.tar.gz | tar xOvz > files/etc/openclash/core/clash_meta
chmod +x files/etc/openclash/core/clash*

#将AdGuardHome核心文件编译进目录
curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest \
| grep "browser_download_url.*AdGuardHome_linux_amd64.tar.gz" \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs curl -L -o /tmp/AdGuardHome_linux_amd64.tar.gz && \
tar -xzvf /tmp/AdGuardHome_linux_amd64.tar.gz -C /tmp/ --strip-components=1 && \
mkdir -p files/usr/bin/AdGuardHome && \
mv /tmp/AdGuardHome/AdGuardHome files/usr/bin/AdGuardHome/
chmod 0777 files/usr/bin/AdGuardHome/AdGuardHome

echo "===================="
echo "结束 DIY 配置..."
