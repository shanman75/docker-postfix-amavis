#!/bin/sh
#
# docker-config.sh
#
# Defines common functions. Source this file from other scripts.
#
# Defined in Dockerfile:
# DOCKER_UNLOCK_FILE
#
HOSTNAME=${HOSTNAME-$(hostname)}
DOMAIN=${HOSTNAME#*.}
TLS_KEYBITS=${TLS_KEYBITS-2048}
TLS_CERTDAYS=${TLS_CERTDAYS-30}

#
# general file manipulation commands, used both during build and run time
#

_escape() { echo "$@" | sed 's|/|\\\/|g' | sed 's|;|\\\;|g'  | sed 's|\$|\\\$|g' | sed "s/""'""/\\\x27/g" ;}

dc_modify() {
	local cfg_file=$1
	shift
	local lhs="$1"
	shift
	local eq=
	local rhs=
	if [ "$1" = "=" ]; then
		eq="$1"
		shift
		rhs="$(_escape $@)"
	else
		rhs="$(_escape $@)"
	fi
	dc_log 7 's/.*('"$lhs"'\s*'"$eq"'\s*)[^#]+(.*)/\1'"$rhs"' \2/g' $cfg_file
	sed -ri 's/.*('"$lhs"'\s*'"$eq"'\s*)[^#]+(.*)/\1'"$rhs"' \2/g' $cfg_file
}

dc_replace() {
	local cfg_file=$1
	local old="$(_escape $2)"
	local new="$(_escape $3)"
	dc_log 7 's/'"$old"'/'"$new"'/g' $cfg_file
	sed -i 's/'"$old"'/'"$new"'/g' $cfg_file
}

dc_addafter() {
	local cfg_file=$1
	local startline="$(_escape $2)"
	local new="$(_escape $3)"
	dc_log 7 '/'"$startline"'/!{p;d;}; $!N;s/\n\s*$/\n'"$new"'\n/g' $cfg_file
	sed -i '/'"$startline"'/!{p;d;}; $!N;s/\n\s*$/\n'"$new"'\n/g' $cfg_file
}

dc_comment() {
	local cfg_file=$1
	local string="$2"
	dc_log 7 '/^'"$string"'/s/^/#/g' $cfg_file
	sed -i '/^'"$string"'/s/^/#/g' $cfg_file
}

dc_uncommentsection() {
	local cfg_file=$1
	local startline="$(_escape $2)"
	dc_log 7 '/^'"$startline"'$/,/^\s*$/s/^#*//g' $cfg_file
	sed -i '/^'"$startline"'$/,/^\s*$/s/^#*//g' $cfg_file
}

dc_removeline() {
	local cfg_file=$1
	local string="$2"
	dc_log 7 '/'"$string"'.*/d' $cfg_file
	sed -i '/'"$string"'.*/d' $cfg_file
}

dc_uniquelines() {
	local cfg_file=$1
	dc_log 7 '$!N; /^(.*)\n\1$/!P; D' $cfg_file
	sed -ri '$!N; /^(.*)\n\1$/!P; D' $cfg_file
}


#
# Persist dirs
#

#
# Make sure that we have the required directory structure in place under
# DOCKER_PERSIST_DIR. It will be missing if we mount an empty volume there.
#
dc_persist_mkdirs() {
	local dirs=$@
	for dir in $dirs; do
		mkdir -p ${DOCKER_PERSIST_DIR}${dir}
	done
}

#
# mv dir to persist location and leave a link to it
#
dc_persist_mvdirs() {
	local srcdirs="$@"
	if [ -n "$DOCKER_PERSIST_DIR" ]; then
		for srcdir in $srcdirs; do
			if [ -e "$srcdir" ]; then
				local dstdir="${DOCKER_PERSIST_DIR}${srcdir}"
				local dsthome="$(dirname $dstdir)"
				if [ ! -d "$dstdir" ]; then
					dc_log 5 "Moving $srcdir to $dstdir"
					mkdir -p "$dsthome"
					mv "$srcdir" "$dsthome"
					ln -sf "$dstdir" "$srcdir"
				else
					dc_log 4 "$srcdir already moved to $dstdir"
				fi
			else
				dc_log 4 "Cannot find $srcdir"
			fi
		done
	fi
}

#
# Conditionally change owner of files.
#
dc_chowncond() {
	local user=$1
	local dir=$2
	if id $user > /dev/null 2>&1; then
		if [ -n "$(find $dir ! -user $user -print -exec chown -h $user: {} \;)" ]; then
			dc_log 5 "Changed owner to $user for some files in $dir"
		fi
	fi
}

#
# Append entry if it is not already there. If mode is -i then append before last line.
#
dc_cond_append() {
	local mode filename lineraw lineesc
	case $1 in
		-i) mode=i; shift;;
		-a) mode=a; shift;;
		 *) mode=a;;
	esac
	filename=$1
	shift
	lineraw=$@
	lineesc="$(echo $lineraw | sed 's/[\";/*]/\\&/g')"
	if [ -e "$filename" ]; then
		if [ -z "$(sed -n '/'"$lineesc"'/p' $filename)" ]; then
			dc_log 7 "dc_cond_append append: $mode $filename $lineraw"
			case $mode in
				a) echo "$lineraw" >> $filename;;
				i) sed -i "$ i\\$lineesc" $filename;;
			esac
		else
			dc_log 4 "Avoiding duplication: $filename $lineraw"
		fi
	else
		dc_log 7 "dc_cond_append create: $mode $filename $lineraw"
		echo "$lineraw" >> $filename
	fi
}

dc_cpfile() {
	local suffix=$1
	shift
	local cfs=$@
	for cf in $cfs; do
		cp "$cf" "$cf.$suffix"
	done
}

dc_mvfile() {
	local suffix=$1
	shift
	local cfs=$@
	for cf in $cfs; do
		mv "$cf" "$cf.$suffix"
	done
}

#
# Prune PID files
#
dc_prune_pidfiles() {
	local dirs=$@
	for dir in $dirs; do
		if [ -n "$(find -H $dir -type f -name "*.pid" -exec rm {} \; 2>/dev/null)" ]; then
			dc_log 5 "Removed orphan pid files in $dir"
		fi
	done
}

#
# TLS/SSL Certificates [openssl]
#
dc_tls_setup_selfsigned_cert() {
	local cert=$1
	local key=$2
	if ([ ! -s $cert ] || [ ! -s $key ]); then
		dc_log 5 "Setup self-signed TLS certificate for host $HOSTNAME"
		openssl genrsa -out $key $TLS_KEYBITS
		openssl req -x509 -utf8 -new -batch -subj "/CN=$HOSTNAME" \
			-days $TLS_CERTDAYS -key $key -out $cert
	fi
}

#
# Configuration Lock
#
dc_lock_config() {
	if dc_is_unlocked; then
		rm $DOCKER_UNLOCK_FILE
	else
		dc_log 5 "No unlock file found, so not touching configuration"
	fi
}

#
# true if there is no lock file or FORCE_CONFIG is not empty
#
dc_is_unlocked() { [ -f "$DOCKER_UNLOCK_FILE" ] || [ -n "$FORCE_CONFIG" ] ;}
