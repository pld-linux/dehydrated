#!/bin/sh

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
deploy_cert)
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
clean_challenge)
	CHALLENGE_TOKEN="$2"
	KEYAUTH="$3"
	echo " + Hook: $1: Nothing to do..."
	;;
deploy_challenge)
	echo " + Hook: $1: Nothing to do..."
	;;
unchanged_cert)
	echo " + Hook: $1: Nothing to do..."
	;;
*)
	echo " + Hook: $1: Nothing to do..."
	;;
esac
