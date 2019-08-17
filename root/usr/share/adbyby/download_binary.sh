#!/bin/sh

	[ "$1" != "--down" ] && return 1
	sleep 2
	# 防止重复启动
	for pid in $(pidof "${0##*/}"); do
		[ "$pid" != "$$" ] && return 1
	done

	if ! mount | grep adbyby >/dev/null 2>&1; then
		echo "Adbyby is not mounted,Stop update!"
		/etc/init.d/adbyby restart >/dev/null 2>&1 &
		return 1
	fi

	while : ; do
		wget-ssl -4 --spider -q -t 1 -T 3 dev.tencent.com
		[ "$?" != "0" ] && sleep 2 || break
	done

	for a in $(opkg print-architecture | awk '{print $2}'); do
		case "$a" in
			all|noarch)
				;;
			arm_arm1176jzf-s_vfp|arm_arm926ej-s|arm_fa526|arm_xscale|armeb_xscale)
				ARCH="arm"
				P="2p"
				;;
			aarch64_cortex-a53|aarch64_cortex-a72|aarch64_generic|arm_cortex-a15_neon-vfpv4|arm_cortex-a5_neon-vfpv4|arm_cortex-a7_neon-vfpv4|arm_cortex-a8_vfpv3|arm_cortex-a9|arm_cortex-a9_neon|arm_cortex-a9_vfpv3|arm_mpcore|arm_mpcore_vfp)
				ARCH="armv7"
				P="4p"
				;;
			mips_24kc|mips_mips32|mips64_mips64|mips64_octeon)
				ARCH="mips"
				P="6p"
				;;
			mipsel_24kc|mipsel_24kec_dsp|mipsel_74kc|mipsel_mips32|mipsel_1004kc_dsp)
				ARCH="mipsel"
				P="8p"
				;;
			x86_64)
				ARCH="x64"
				P="10p"
				;;
			i386_pentium|i386_pentium4)
				ARCH="x86"
				P="12p"
				;;
			*)
				echo_date "不支持当前CPU架构 $a"
				return 1
				;;
		esac
	done

	rm -f /usr/share/adbyby/adbyby /usr/share/adbyby/md5 /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock
	echo "开始下载Adbyby二进制文件..."
	wget-ssl -4 -t 9 -T 3 -O /usr/share/adbyby/adbyby https://dev.tencent.com/u/Small_5/p/adbyby/git/raw/master/$ARCH
	if [ "$?" == "0" ]; then
		chmod +x /usr/share/adbyby/adbyby
	else
		echo "下载Adbyby二进制文件失败，请重试！"
		rm -f /usr/share/adbyby/adbyby
	fi

	echo "开始下载MD5文件..."
	wget-ssl -4 -t 9 -T 3 -O /usr/share/adbyby/md5 https://dev.tencent.com/u/Small_5/p/adbyby/git/raw/master/md5
	if [ "$?" != "0" ]; then
		echo "下载MD5文件失败，请重试！"
		rm -f /usr/share/adbyby/adbyby /usr/share/adbyby/md5
	fi

	md5_local=$(md5sum /usr/share/adbyby/adbyby | awk -F' ' '{print $1}')
	md5_online=$(sed 's/":"/\n/g' /usr/share/adbyby/md5 | sed 's/","/\n/g' | sed -n "$P")
	rm -f /usr/share/adbyby/md5
	if [ "$md5_local"x != "$md5_online"x ]; then
		echo "校验Adbyby二进制文件MD5失败，请重试！"
		rm -f /usr/share/adbyby/adbyby
	fi

	if [ "$(uci -q get adbyby.@adbyby[0].wan_mode)" == "1" ]; then
		echo "开始下载Adblock规则文件..."
		mkdir -p /usr/share/adbyby/adbyby_adblock
		wget-ssl -4 -t 9 -T 3 -O /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock https://dev.tencent.com/u/Small_5/p/adbyby/git/raw/master/dnsmasq.adblock
		if [ "$?" != "0" ];then
			echo "下载Adblock规则失败，请重试！"
			rm -f /usr/share/adbyby/adbyby /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock
		fi

		echo "开始下载Adblock规则MD5文件..."
		wget-ssl -4 -t 9 -T 3 -O /usr/share/adbyby/md5 https://dev.tencent.com/u/Small_5/p/adbyby/git/raw/master/md5_1
		if [ "$?" != "0" ]; then
			echo "下载Adblock规则MD5文件失败，请重试！"
			rm -f /usr/share/adbyby/adbyby /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock /usr/share/adbyby/md5
		fi

		md5_local=$(md5sum /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock | awk -F' ' '{print $1}')
		md5_online=$(sed 's/":"/\n/g' /usr/share/adbyby/md5 | sed 's/","/\n/g' | sed -n '2P')
		rm -f /usr/share/adbyby/md5
		if [ "$md5_local"x != "$md5_online"x ]; then
			echo "校验Adblock规则MD5失败，请重试！"
			rm -f /usr/share/adbyby/adbyby /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock
		fi
	fi
	/etc/init.d/adbyby restart >/dev/null 2>&1 &
