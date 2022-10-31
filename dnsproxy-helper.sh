#!/bin/sh
cwd=$(dirname $(realpath $0))
resolv_conf="/etc/adguard/resolv.conf"
resolv_head="/etc/resolvconf/resolv.conf.d/head"
case "${1}" in
	start)
	grep -o '^[^#]*' ${resolv_conf} > ${resolv_head}
	[ -z $(grep '^options\ edns0$' ${resolv_conf}) ] && echo 'options edns0' >> ${resolv_head}
	resolvconf -u
	listen=$(grep -o '^[^#]*' ${resolv_conf} | sed 's/^nameserver\ /--listen=/g')
	${cwd}/dnsproxy ${listen} --config-path=/etc/adguard/dnsproxy.yml
	;;
	stop)
	> ${resolv_head}
	resolvconf -u
	;;
esac
