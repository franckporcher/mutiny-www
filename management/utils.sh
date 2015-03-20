#!/bin/bash
#
# utils.sh -- Bash toolbox for local bash-based utilities
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

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

function do () {
	echo "DO: $*" 1>&2
	"$@"
}

function do_continue () {
	echo "DO: $*" 1>&2
	"$@"

    echo -n "Continue: [N/y]> " 1>&2
    read choice

    if [ "$choice" == "y" ]
    then
        return 0
    else
        die "Abandon."
    fi
}

# Choose one.
#   echo :       trace but do nothing
#   do_continue: reports step by step operation, with the option to exit the script at each step
#   do         : reports step by step operation
#DO=do
#DO=do_continue
#DO=echo
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

