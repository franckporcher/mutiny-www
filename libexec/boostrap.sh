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
    msg="[$SCRIPTFQN/$(pwd)] Error:: $*. Aborting!"
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
# GITHUB STUFF
#----------------------------------------

##
# Locally clone the reference repository gor the given module
#
function bootstrap_module () {
    module_name="$1"
    git_repos_name="$2"
    git_branch_name="$3"
    install_dir="$4"

    # 1. Move to install_dir 
    [ ! -d "${install_dir}" ] &&  $DO mkdir -p "${install_dir}"
    $DO cd "${install_dir}" || die "Cannot cd:[${install_dir}] for bootstrapping module:[$module_name]"

    # 2. Retrieve remote distribution
    $DO $GIT clone --branch "${git_branch_name}" "ssh://git@github.com/franckporcher/${git_repos_name}.git" .
}

#
# main
#
function main() {
    # Stage 1 Bootstrap : Install le chapeau
    top_module_name=mutiny
    $DO bootstrap_module "${top_module_name}" mutiny-www stable-v1.0 ~/gitdeploy || die "bootstrap_module died: $!"

    # STAGE 2 Bootstrap : Install hooks and submodules using the installed libexec
    $DO ./libexec/install_module.sh -bootstrap || die "[main] ./libexec/boostrap.post.sh died: $!"
}

main
