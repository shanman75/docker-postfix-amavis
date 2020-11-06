#!/bin/sh
#
# dovecot-common.sh
#
# Define variables and functions used during build. Source in Dockerfile.
#
# Defined in Dockerfile:
# DOCKER_IMAP_DIR DOCKER_APPL_RUNAS DOCKER_IMAP_PASSDB_FILE
#
DOVECOT_CF=${DOVECOT_CF-$DOCKER_IMAP_DIR/dovecot.conf}
DOVECOT_CD=${DOVECOT_CD-$DOCKER_IMAP_DIR/conf.d}

#
# Configure dovecot.
#
dc_dovecot_setup_docker() {
	dc_dovecot_setup_conf
	dc_dovecot_setup_auth
	dc_dovecot_setup_debug
}

#
# Configure dovecot local config.
#
dc_dovecot_setup_conf() {
	local example_conf=/usr/share/dovecot/example-conf
	mkdir -p $example_conf
	mv $DOCKER_IMAP_DIR/* $example_conf
	mkdir -p $DOVECOT_CD
	cat <<-!cat > $DOVECOT_CF
		!include conf.d/*.conf
	!cat
	cat <<-!cat > $DOCKER_IMAP_DIR/README
		You can find dovecot example config files here: $example_conf
	!cat
}

#
# Configure dovecot auth service.
#
dc_dovecot_setup_auth() {
	cat <<-!cat > $DOVECOT_CD/10-auth.conf
		ssl = no
		disable_plaintext_auth = no
		auth_mechanisms = plain
		service auth {
		unix_listener /var/spool/postfix/private/auth {
		mode  = 0660
		user  = $DOCKER_APPL_RUNAS
		group = $DOCKER_APPL_RUNAS
		}
		}
	!cat
}

#
# Configure dovecot to use passwd-file.
#
dc_dovecot_setup_debug() {
	cat <<-!cat > $DOVECOT_CD/50-debug.conf
		auth_debug=yes
		auth_debug_passwords=yes
	!cat
}
