#!/bin/bash
#
# bootstrap.local.sh -- Bootstrap MUTINY Tahiti's Website
#                       from github main-module and submodules specifications
#                       For OS X local development platform only 
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 2014-2015 - Franck Porcher, Ph.D 
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
    local msg="[$SCRIPTFQN (~/$(pwd))] --> $*"
    echo "$msg" 1>&2
    log "$msg"
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
    ##
    # Stage 1 Bootstrap : Install le chapeau
    local git_repos_name=mutiny-www
    local git_branch_name=stable-v1.0 
    local fresh_install_dir=/mutiny

    if [ ! -d "${fresh_install_dir}" ]
    then
        mkdir -p "${fresh_install_dir}"
    fi

    $DO $GIT clone --branch "${git_branch_name}" "git://github.com/franckporcher/${git_repos_name}.git" "$fresh_install_dir" || die "$SCRIPTFQN died: $!"
    
    ##
    # STAGE 2 Bootstrap : Install hooks and submodules using the installed libexec
    $DO cd "$fresh_install_dir/libexec"
    $DO ./install_module.sh -bootstrap "$@" || die "[main] $SCRIPTFQN died: $!"
}

if [ $# -lt 1 ]
then
    ${DO} main --all
else
    ${DO} main "$@"
fi
