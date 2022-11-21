#!/bin/sh
dnsproxy="$(dirname $(realpath $0))/dnsproxy"
resolv_file="/etc/resolvconf/resolv.conf.d/head"
case "${1}" in
	start)
	listen=$($dnsproxy --config-path=/etc/adguard/dnsproxy.yml | tee -a /dev/tty | sed '/Listening/!d;s/.*:\/\/\(.\+\):.*/\1/g' | uniq)
	resolv=$(cat $resolv_file)
	for ip in $listen; do
		case $resolv in
			*${ip}*) ;;
			*) echo "nameserver ${ip}" >> $resolv_file;;
		esac
	done
	[ -z $(grep '^options\ edns0$' $resolv_file) ] && echo 'options edns0' >> $resolv_file
	resolvconf -u
	;;
	stop)
	killall -9 $dnsproxy
	lsof=$(sudo lsof -Pni:53 | sed '/LISTEN/!d;s/.*\(TCP\|UDP\)\ //g;s/:53.*//g')
	nameservers=$(grep -o ^nameserver.*$ $resolv_file | awk '{print $2}')
	for ip in $nameservers; do
		case $lsof in
			*${ip}*) echo $ip;;
			*) sed -i "/^nameserver.*${ip}$/d" $resolv_file;;
		esac
	done
	sed -i 's/^options\ edns0$//' $resolv_file
	resolvconf -u
	;;
esac
