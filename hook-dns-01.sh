#!/bin/bash

# based on https://github.com/lukas2511/dehydrated/wiki/example-dns-01-nsupdate-script

set -e
set -u
set -o pipefail

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
		if [ -x /etc/rc.d/init.d/apache ]; then
			echo " + Hook: Overwritting /etc/httpd/ssl/server.{crt,key}, /etc/httpd/ssl/ca.crt and reloading Apache..."
			cp -a /etc/apache/server.crt /etc/apache/server.crt.letsencrypt~
			cp -a /etc/apache/server.key /etc/apache/server.key.letsencrypt~
			cp -a /etc/apache/ca.crt /etc/apache/ca.crt.letsencrypt~
			cat "$CERT" > /etc/apache/server.crt
			cat "$PRIVKEY" > /etc/apache/server.key
			cat "$CHAINCERT" > /etc/apache/ca.crt
			/sbin/service apache restart
		fi
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

