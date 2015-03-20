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

ROOT_DIR=.

# 
# cd to the root repository
#
cd "$(dirname "$0")"

#----------------------------------------------------------------------------
# GITHUB BRANCHES SPECIFICATION
#----------------------------------------------------------------------------
declare -A RELEASE

#------[moduleName]--ReposName:BranchName---
RELEASE[mutiny-www]='mutiny-www:stable-v1.0'        # MAIN
RELEASE[wordpress]='mutiny-www-wp:init-4.1.1-v1.0'  # STATIC SITE
RELEASE[store]='mutiny-www-ps:init-1.6.0.14-v1.0'   # MERCHAND SITE
RELEASE[cgm]='mutiny-www-cgm:stable-v1.0'           # CATALOGUE GLOBAL MUTINY

#----------------------------------------
# COMMON VARS
#----------------------------------------
BOOTSTRAP_MAIN=update-modules.sh
BOOTSTRAP_SUBMODULE=update-submodule.sh

## MUTINY SUBMODULES
MUTINY_MODULES=(wordpress store cgm)


#----------------------------------------
# DEBUG
#----------------------------------------
function log () {
    logger -s -t "$(basename $0)" "$*"
}

function die () {
    echo "ERROR: $*. Exiting!" 1>&2
    log  "ERROR: $*. Exiting!"
    exit 1
}

DO=

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
__bootstrap REALPATH realpath __realpath
    # $resolved_path="$(__realpath $path)"
    function __realpath () {
        echo "$1"
    }

__bootstrap CURL curl __curl
    function __curl () {
        __nocmd curl "$*"
    }

__bootstrap UNZIP unzip __unzip
    function __unzip () {
        __nocmd unzip "$*"
    }


#----------------------------------------
# GITHUB STUFF
#----------------------------------------

##
# Download a zip from a github repository and install it
#
# install_github_branch INSTALLDIR (. by default)
function install_github_branch () {
    install_dir="${1:-.}"

    # 1. Get the repository name and the branch name to fetch
    dirname="$(basename "$(pwd)" )"
    repos_def="${RELEASE["$dirname"]}" #git-repos-name:branch-name
    [ -z "$repos_def" ] && die "No known github repository for '$dirname'"

    OIFS="$IFS"
    IFS=':'
    set $repos_def
    IFS="$OIFS"
    repos_name="$1"
    branch_name="$2"
    zipdirname="${repos_name}-${branch_name}"
    zipfile="${repos_name}-${branch_name}.zip"

    # 2. Fetch the stuff
    $CURL -s -f -C - --retry 9 --retry-delay 5 -o "${zipfile}"  "https://codeload.github.com/franckporcher/${repos_name}/zip/${branch_name}"
    if [ -s "${zipfile}" ]
    then
        # The zip archive contains one directory named ${repos_name}-${branch_name}
        # We should extract the content of this dir into the current dir,
        # instead of creating that dir into the current dir
        # we do the trick by creating a symbolink link
        ln -s "${install_dir}" "${zipdirname}"
        $UNZIP -q -o -d . "${zipfile}"
        rm "${zipdirname}"
        rm "${zipfile}"
    fi
}

function update_mutiny_module () {
    module="$1"
    # Boostrap submodule 
    if [ -e "${module}/${BOOTSTRAP_SUBMODULE}" ]
    then
        pushd "${module}" &> /dev/null
        "./${BOOTSTRAP_SUBMODULE}"
        popd &> /dev/null
    fi
}

#
# main
#
function main() {
    # Install Main
    install_github_branch

    # Install Submodules   
    for module in "${MUTINY_MODULES[@]}"
    do
        update_mutiny_module "${module}"
    done
}

main
