#!/bin/sh
# based on https://github.com/lukas2511/dehydrated/wiki/example-dns-01-nsupdate-script

set -eu

# concat file atomic way
atomic_concat() {
	local file=$1; shift
	> $file.new
	chmod 600 $file.new
	cat "$@" > $file.new
	cp -f $file $file.dehydrated~
	mv -f $file.new $file
}

lighttpd_reload() {
	if [ ! -x /usr/sbin/lighttpd ] || [ ! -f /etc/lighttpd/server.pem ]; then
		return
	fi

	echo " + Hook: Overwritting /etc/lighttpd/server.pem and reloading lighttpd..."
	atomic_concat /etc/lighttpd/server.pem "$FULLCHAINCERT" "$PRIVKEY"
	/sbin/service lighttpd reload
}

haproxy_reload() {
	if [ ! -x /usr/sbin/haproxy ] || [ ! -f /etc/haproxy/server.pem ]; then
		return
	fi

	echo " + Hook: Overwritting /etc/haproxy/server.pem and restarting haproxy..."
	atomic_concat /etc/haproxy/server.pem "$FULLCHAINCERT" "$PRIVKEY"
	/sbin/service haproxy reload
}

nginx_reload() {
	if [ ! -f /etc/nginx/server.crt ] || [ ! -f /etc/nginx/server.key ]; then
		return
	fi

	echo " + Hook: Overwritting /etc/nginx/server.{crt,key} and reloading nginx..."
	atomic_concat /etc/nginx/server.crt "$FULLCHAINCERT"
	atomic_concat /etc/nginx/server.key "$PRIVKEY"
	/sbin/service nginx reload
}

httpd_reload() {
	if [ ! -x /etc/rc.d/init.d/httpd ]; then
		return
	fi

	echo " + Hook: Reloading Apache 2..."
	atomic_concat /etc/httpd/ssl/server.crt "$FULLCHAINCERT"
	atomic_concat /etc/httpd/ssl/server.key "$PRIVKEY"
	/sbin/service httpd graceful
}

case "$1" in
	"deploy_challenge")
		echo ""
		echo "Add the following to the zone definition of ${2}:"
		echo "'_acme-challenge.${2}:${4}:300"
		echo ""
		echo -n "Press enter to continue..."
		read tmp
		echo ""
	;;
	"clean_challenge")
		echo ""
		echo "Now you can remove the following from the zone definition of ${2}:"
		echo "'_acme-challenge.${2}:${4}:300"
		echo ""
		echo -n "Press enter to continue..."
		read tmp
		echo ""
	;;
	"deploy_cert")
		DOMAIN="$2"
		PRIVKEY="$3"
		CERT="$4"
		FULLCHAINCERT="$5"
		CHAINCERT="$6"
		TIMESTAMP="$7"

		lighttpd_reload
		nginx_reload
		httpd_reload
		haproxy_reload
	;;
	"unchanged_cert")
		# do nothing for now
	;;
	*)
		echo "Unknown hook \"${1}\""
		exit 1
	;;
esac

exit 0
