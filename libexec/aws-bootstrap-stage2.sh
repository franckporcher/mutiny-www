#!/bin/bash
#
# aws-bootstrap-stage2.sh -- 2nd stage Bootstrap MUTINY Tahiti's Website
#                 within the AWS EC2 Instance
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

#----------------------------------------
# BEGIN
#----------------------------------------
cd "$(dirname "$0")"
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"

#----------------------------------------
# DEBUG
#----------------------------------------
function log () {
    logger -s -t "$SCRIPTNAME" "$*"
}

function die () {
    local msg="[ERROR::$SCRIPTFQN (~$(pwd))] $*. Aborting!"
    echo "$msg" 1>&2
    log "$msg"
    exit 1
}

function do_log () {
    log "[TRACE::$SCRIPTFQN (~/$(pwd))] --> $*"
    "$@"
}

DO=do_log

#----------------------------------------
# TOOLS AVAILABILITY CHECKING
#----------------------------------------
##
#
#__bootstrap REALPATH realpath __realpath
#
function __bootstrap() {
    local util_ref_name="$1"
    local util_real_name="$2"
    local util_bs_name="$3"

    local _path="$(which "${util_real_name}")"
    [ -z "${_path}" ] && _path="${util_bs_name}"

    eval "${util_ref_name}='${_path}'"
}

##
# __nocmd cmd arg...
function __nocmd () {
    local cmd="$1"
    die "Unknown command: ${cmd} [$*]"
}

##
# TOOLS NEEDED
#
__bootstrap GIT git __git
    function __git () {
        __nocmd git "$*"
    }


#----------------------------------------
# main
#----------------------------------------
function main() {
    $DO ./install_module.sh -bootstrap || die "[main] ${SCRIPTFQN} died: $!"
}

${DO} main "$@"
