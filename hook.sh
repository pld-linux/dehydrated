#!/bin/sh

case "$1" in
deploy_cert)
	DOMAIN="$2"
	PRIVKEY="$3"
	CERT="$4"
	FULLCHAINCERT="$5"
	CHAINCERT="$6"
	TIMESTAMP="$7"
	if [ -x /usr/sbin/lighttpd -a -f /etc/lighttpd/server.pem ]; then
		echo " + Hook: Overwritting /etc/lighttpd/server.pem and reloading lighttpd..."
		cp -a /etc/lighttpd/server.pem /etc/lighttpd/server.pem.letsencrypt~
		cat "$FULLCHAINCERT" "$PRIVKEY" > /etc/lighttpd/server.pem
		/sbin/service lighttpd reload
	fi
	if [ -f /etc/nginx/server.pem -a -f /etc/nginx/server.key ]; then
		echo " + Hook: Overwritting /etc/nginx/server.{pem,key} and reloading nginx..."
		cp -a /etc/nginx/server.pem /etc/nginx/server.pem.letsencrypt~
		cp -a /etc/nginx/server.key /etc/nginx/server.key.letsencrypt~
		cat "$FULLCHAINCERT" > /etc/nginx/server.pem
		cat "$PRIVKEY" > /etc/nginx/server.key
		/sbin/service nginx reload
	fi
	if [ -x /etc/rc.d/init.d/httpd ]; then
		echo " + Hook: Reloading Apache..."
		/sbin/service httpd graceful
	fi
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
