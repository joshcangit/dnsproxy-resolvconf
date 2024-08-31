#!/bin/sh
dnsproxy="$(dirname $(realpath $0))/dnsproxy"
yaml="/etc/adguard/dnsproxy.yml"
resolv_file="/etc/resolvconf/resolv.conf.d/head"
listen=$(cat $yaml | sed '/^listen-addrs:/,/^.\+:/!d;/:/d' | cut -d\" -f2)
case "${1}" in
	start)
	resolv=$(cat $resolv_file)
	for ip in $listen; do
		case $resolv in
			*${ip}*) ;;
			*) echo "nameserver ${ip}" >> $resolv_file;;
		esac
	done
	resolvconf -u
	$dnsproxy --config-path=$yaml
	;;
	stop)
	killall -9 $dnsproxy
	resolv=$(cat $resolv_file)
	for ip in $listen; do
		case $resolv in
			*${ip}*) sed -i "/^nameserver.*${ip}$/d" $resolv_file;;
		esac
	done
	resolvconf -u
	;;
esac
