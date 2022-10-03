#!/bin/sh
cwd=$(dirname $(realpath $0))
resolv_conf="/etc/adguard/resolv.conf"
resolv_tail="/etc/resolvconf/resolv.conf.d/tail"
case "${1}" in
	start)
	grep -o '^[^#]*' ${resolv_conf} > ${resolv_tail}
	[ -z $(grep '^options\ edns0$' ${resolv_conf}) ] && echo 'options edns0' >> ${resolv_tail}
	resolvconf -u
	listen=$(grep -o '^[^#]*' ${resolv_conf} | sed 's/^nameserver\ /--listen=/g')
	${cwd}/dnsproxy ${listen} --config-path=/etc/adguard/dnsproxy.yml
	;;
	stop)
	> ${resolv_tail}
	resolvconf -u
	;;
esac
