#!/bin/bash
#
# bootstrap.sh -- Bootstrap MUTINY Tahiti's Website
#                 from github main-module and submodules specifications
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

#----------------------------------------
# DEBUG
#----------------------------------------
function log () {
    logger -s -t "$SCRIPTNAME" "$*"
}

function die () {
    msg="[$SCRIPTFQN (~$(pwd))] Error:: $*. Aborting!"
    echo "$msg" 1>&2
    log "$msg"
    exit 1
}

function do_log () {
    log "PWD:[$(pwd)] CMD:[$*]"
    "$@"
}

DO=do_log
   

#----------------------------------------
# BEGIN
#----------------------------------------
cd "$(dirname "$0")"
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"

#----------------------------------------
# TOOLS AVAILABILITY CHECKING
#----------------------------------------
##
#
#__bootstrap REALPATH realpath __realpath
#
function __bootstrap() {
    util_ref_name="$1"
    util_real_name="$2"
    util_bs_name="$3"

    _path="$(which "${util_real_name}")"
    [ -z "${_path}" ] && _path="${util_bs_name}"

    eval "${util_ref_name}='${_path}'"
}

##
# __nocmd cmd arg...
function __nocmd () {
    cmd="$1"
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
    git_repos_name=mutiny-www
    git_branch_name=stable-v1.0 
    fresh_install_dir=~/gitdeploy


    $DO $GIT clone --branch "${git_branch_name}" "ssh://git@github.com/franckporcher/${git_repos_name}.git" "$fresh_install_dir" \
        die "bootstrap_module died: $!"
    
    ##
    # STAGE 2 Bootstrap : Install hooks and submodules using the installed libexec
    cd "$fresh_install_dir"
    $DO ./libexec/install_module.sh -bootstrap || die "[main] $(pwd)/libexec/boostrap.post.sh died: $!"
}

main
