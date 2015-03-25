# utils.sh -- Bash toolbox for local bash-based utilities
#
# PROJECT: MUTINY Tahiti's websites
#
# File to be SOURCED, not ran directly
#
# LIBEXEC must be defined or taken as . as default
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés

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

function do () {
	echo "DO: $*" 1>&2
	"$@"
}

function do_log () {
    log "[TRACE::$SCRIPTFQN (~/$(pwd))] --> $*"
    "$@"
}

function do_continue () {
	echo "DO: $*" 1>&2
	"$@"

    echo -n "Continue: [N/y]> " 1>&2
    local choice
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
#DO=echo
#DO=do_continue
#DO=do_log
#DO=do
DO=do_log

#----------------------------------------
# BEGIN
#----------------------------------------
[ -z "${LIBEXEC}" ] && LIBEXEC="$(pwd)"             # $(pwd) because at this stage we must be positionned
                                                    # INSIDE the libexec directory by the caller, 
                                                    # who is supposed to have done a cd $(dirname $0)
[ -z "${DEFINES}" ] && DEFINES="${LIBEXEC}/DEFINES"
[ -z "${UTILS}" ]   && UTILS="${LIBEXEC}/utils.sh"
export LIBEXEC DEFINES UTILS

if [ -e "${DEFINES}" ]
then
    source "${DEFINES}"
else
    die "[${UTILS} Cannot locate mandatory dependancy:[${DEFINES}]"
fi

#----------------------------------------
# TOOLS AVAILABILITY CHECKING
#
#   awk
#   curl
#   git
#   mysql
#   realpath
#   unzip
#   
#----------------------------------------
##
#__bootstrap CMD unixcmd __shellfunction
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
#
function __nocmd () {
    local cmd="$1"
    die "Unknown command: ${cmd} [$*]"
}

##
# TOOLS NEEDED
#

__bootstrap AWK awk __awk
    function __awk () {
        __nocmd awk "$*"
    }

__bootstrap CURL curl __curl
    function __curl () {
        __nocmd curl "$*"
    }

__bootstrap GIT git __git
    function __git () {
        __nocmd git "$*"
    }

__bootstrap MYSQL mysql __mysql
    function __mysql () {
        __nocmd mysql "$*"
    }

__bootstrap REALPATH realpath __realpath
    function __realpath () {
        echo "$1"
    }

__bootstrap UNZIP unzip __unzip
    function __unzip () {
        __nocmd unzip "$*"
    }

#----------------------------------------
# HELPERS
#----------------------------------------
function _RUN_SCRIPT () {
    local script="$1"; shift

    if [ -e "${script}" ]
    then
        if [ -x "${script}" ] 
        then
            LIBEXEC="${LIBEXEC}" \
            DEFINES="${DEFINES}" \
            UTILS="${UTILS}" \
                $DO "${script}" "$@"
        else 
            LIBEXEC="${LIBEXEC}" \
            DEFINES="${DEFINES}" \
            UTILS="${UTILS}" \
                $DO $BASH "${script}" "$@"
        fi
    fi
}

#----------------------------------------
# FILE STUFF
#----------------------------------------
#owner=$( file_owner file )
function file_owner () {
    ls -ld "$1" | $AWK '{print $3}'
}

# script_pre = $(get_pre script.sh modulename)
function get_pre () {
    local scriptname="$1"
    local modulename="$2"

    echo "${LIBEXEC}/modules/${modulename}/$(basename "${scriptname}" .sh).pre.sh"
}

# script_post = $(get_post script.sh modulename)
function get_post () {
    local scriptname="$1"
    local modulename="$2"

    echo "${LIBEXEC}/modules/${modulename}/$(basename "${scriptname}" .sh).post.sh"
}

# script_middle = $(get_mid script.sh modulename)
function get_mid () {
    local scriptname="$1"
    local modulename="$2"

    echo "${LIBEXEC}/modules/${modulename}/$(basename "${scriptname}" .sh).mid.sh"
}

#----------------------------------------
# GITHUB STUFF
#----------------------------------------

##
# module_specs=$(get_module_specs module_name)
#
function get_module_specs () {
    local module_name="$1"
    local specs="${INITIAL_RELEASE["${module_name}"]}"
    set $specs
    [ $# -ne 3 ] && die "Invalid module spec:[$specs]"
    local repos_name="$1"
    local branch_name="$2"
    eval "install_dir=$3"   # for possible ~ expansion
    echo "$repos_name" "$branch_name" "$install_dir"
}

##
# top_module=$(get_topmodule)
#
function get_topmodule () {
    echo "${MODULES[root]}"
}

##
# submodules_list=$(get_submodules_list module_name)
#
function get_submodules_list () {
    local module_name="$1"
    echo "${MODULES["${module_name}"]}"
}

##
# git_url=$(git_url repos_name)
#
# Clone into a given dir the reference repository
# for a given module
# 
function git_url () {
    echo "${GIT_URL}/${1}.git"
}

##
# Download a zip from a github repository and install it
#
# install_git_distribution module
function install_git_distribution () {
    local module_name="$1"

    [ -z "${module_name}" ] && die "[install_git_distribution] Usage: install_git_distribution <module_name>"

    set ${INITIAL_RELEASE["${module_name}"]}
    [ $# -ne 3 ] && die "[install_git_distribution] Invalid git module specification:[${INITIAL_RELEASE["${module_name}"]}]"

    local repos_name="$1"
    local branch_name="$2"
    eval "install_dir=$3"   # for possible ~ expansion

    local zipdirname="${repos_name}-${branch_name}"
    local zipfile="${repos_name}-${branch_name}.zip"

    # 2. Fetch the stuff
    $CURL -s -f -C - --retry 9 --retry-delay 5 -o "${zipfile}"  "https://codeload.github.com/franckporcher/${repos_name}/zip/${branch_name}"
    if [ -s "${zipfile}" ]
    then
        # Create the recipient directory, unless it exists
        [ ! -d "${install_dir}" ] && mkdir -p "${install_dir}"

        # The zip archive comprises one directory named ${repos_name}-${branch_name}
        # We must extract the content of this dir into the install_dir
        # instead of creating that dir into the current dir
        # We do the trick by creating a symbolink on the recipient, so the
        # archive will decompress into it ;)
        ln -s "${install_dir}" "${zipdirname}"
        $UNZIP -q -o -d . "${zipfile}"
        rm "${zipdirname}"
        rm "${zipfile}"
    fi
}

