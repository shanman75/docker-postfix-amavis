#!/bin/sh
#
# docker-acme.inc
#
# Define variables and functions used during container initialization here
# and source this file in docker-entry.d and docker-exit.d files.
#
source docker-modfile.inc

#
# Variables
#

ACME_FILE=${ACME_FILE-/acme/acme.json}
HOSTNAME=${HOSTNAME-$(hostname)}
DOMAIN=${HOSTNAME#*.}
DOCKER_ACME_SSL_DIR=${DOCKER_ACME_SSL_DIR-/etc/ssl/acme}
DOCKER_AST_SSL_DIR=${DOCKER_AST_SSL_DIR-/etc/ssl/asterisk}
DOCKER_AST_SSL_CERT=$DOCKER_AST_SSL_DIR/asterisk.cert.pem
DOCKER_AST_SSL_KEY=$DOCKER_AST_SSL_DIR/asterisk.priv_key.pem
DOCKER_ACME_SSL_H_CERT=$DOCKER_ACME_SSL_DIR/certs/${HOSTNAME}.crt
DOCKER_ACME_SSL_H_KEY=$DOCKER_ACME_SSL_DIR/private/${HOSTNAME}.key
DOCKER_ACME_SSL_D_CERT=$DOCKER_ACME_SSL_DIR/certs/${DOMAIN}.crt
DOCKER_ACME_SSL_D_KEY=$DOCKER_ACME_SSL_DIR/private/${DOMAIN}.key

setup_runit_acme_dump() {
	if (dc_is_installed jq && [ -s $ACME_FILE ]); then
		dc_log 5 "Setup ACME TLS certificate monitoring"
		setup-runit.sh "-n acme $(which inotifyd) $(which dumpcerts.sh) $ACME_FILE:c"
		# run dumpcerts.sh on cnt creation (and every time the json file changes)
		# dumpcerts.sh reports to logger but it is yet to be started so this run will be quiet
		dumpcerts.sh $ACME_FILE $DOCKER_ACME_SSL_DIR
	fi
}

setup_acme_tls_cert() {
	if ([ -r $DOCKER_ACME_SSL_H_CERT ] && [ -r $DOCKER_ACME_SSL_H_KEY ]); then
		dc_log 5 "Seting up ACME TLS certificate for host $HOSTNAME"
		ln -sf $DOCKER_ACME_SSL_H_CERT $DOCKER_AST_SSL_CERT
		ln -sf $DOCKER_ACME_SSL_H_KEY $DOCKER_AST_SSL_KEY
	else
		if ([ -r $DOCKER_ACME_SSL_D_CERT ] && [ -r $DOCKER_ACME_SSL_D_KEY ]); then
			dc_log 5 "Seting up ACME TLS certificate for domain $DOMAIN"
			ln -sf $DOCKER_ACME_SSL_D_CERT $DOCKER_AST_SSL_CERT
			ln -sf $DOCKER_ACME_SSL_D_KEY $DOCKER_AST_SSL_KEY
		fi
	fi
}


