# utils.sh -- Bash toolbox for local bash-based utilities
#
# PROJECT: MUTINY Tahiti's websites
#
# File to be SOURCED, not ran directly
#
# MUTINY_ROOT_INSTALL must be defined or taken as . as default
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
    msg="[ERROR:$SCRIPTFQN] $*. Aborting!"
    echo "$msg" 1>&2
    log "$msg"
    exit 1
}

function do () {
	echo "DO: $*" 1>&2
	"$@"
}

function do_log () {
    log "PWD:[$(pwd)] CMD:[$*]"
    "$@"
}

function do_continue () {
    local choice

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
#DO=echo
#DO=do_continue
#DO=do_log
#DO=do
DO=do_log

#----------------------------------------
# BEGIN
#----------------------------------------
[ -z "${MUTINY_ROOT_INSTALL}" ] && MUTINY_ROOT_INSTALL="$(pwd)"
[ -z "${DEFINES}" ]             && DEFINES="${MUTINY_ROOT_INSTALL}/management/DEFINES"
[ -z "${UTILS}" ]               && UTILS="${MUTINY_ROOT_INSTALL}/management/utils.sh"
export MUTINY_ROOT_INSTALL DEFINES UTILS

if [ -e "${DEFINES}" ]
then
    source "${DEFINES}"
else
    die "[utils.sh] Cannot locate mandatory dependancy:[${DEFINES}]"
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
    script="$1"
    shift

    if [ -e "${script}" ]
    then
        if [ -x "${script}" ] 
        then
            $DO "${script}" "$@"
        else 
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

#----------------------------------------
# GITHUB STUFF
#----------------------------------------

##
# Download a zip from a github repository and install it
#
# install_git_distribution module
function install_git_distribution () {
    module_name="$1"

    [ -z "${module_name}" ] && die "[install_git_distribution] Usage: install_git_distribution <module_name>"

    set ${INITIAL_RELEASE["${module_name}"]}
    [ $# -ne 3 ] && die "[install_git_distribution] Invalid git module specification:[${INITIAL_RELEASE["${module_name}"]}]"

    repos_name="$1"
    branch_name="$2"
    eval "install_dir=$3"   # for possible ~ expansion

    zipdirname="${repos_name}-${branch_name}"
    zipfile="${repos_name}-${branch_name}.zip"

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
# bootstrap_module module_name git_repos_name git_branch_name install_dir
#
# Clone into a given dir the reference repository
# for a given module
# 
function bootstrap_module () {
    module_name="$1"
    git_repos_name="$2"
    git_branch_name="$3"
    install_dir="$4"

    # 1. Move to install_dir 
    if [ -d "${install_dir}" ]
    then
        nodir_flag=
    else
        nodir_flag=1
    fi

    # 2. Retrieve remote distribution
    # $GIT_URL="ssh://git@github.com/franckporcher"
    if [ -n "${nodir_flag}" ]
    then # Recipient directory does not not exists : good !
        $DO $GIT clone --branch "${git_branch_name}" "$( git_url "${git_repos_name}" )" "${install_dir}"   \
            || die "[bootstrap_module] Cannot git clone ${git_repos_name}/${git_branch_name} into "${install_dir}" ($!)"

        # Transfer ownership to WWW
        dirname="$(basename "$(pwd)")"
        chown -R "${WWWUID}:${WWWGID}" "${install_dir}"

    else # Recipient directory exists and may not be empty : not so good...

        # Create a .gitignore with everything present into it
        ls -A > .gitignore
        owner="$(file_owner .gitignore)"

        # Clone git repository into a new temporary sub directory
        tmpdir="__git_tmp_$(date "+%s")"
        $DO $GIT clone --branch "${git_branch_name}" "$( git_url "${git_repos_name}" )" "${tmpdir}" \
            || die "[bootstrap_module] Cannot git clone ${git_repos_name}/${git_branch_name} into ${tmpdir} ($!)"
        chown -R "${WWWUID}:${WWWGID}" "${tmpdir}"

        # Move everything into install directory
        mv ${tmpdir}/*      "${install_dir}"
        mv ${tmpdir}/.[!.]* "${install_dir}"
        rm -rf "${tmpdir}"
    fi

    # 3. REC 
    $DO rec_bootstrap_module "${git_repos_name}"    || die "[bootstrap_module] rec_bootstrap_module died: $!"

    # 4. Post bootstrap 
    MUTINY_ROOT_INSTALL="${MUTINY_ROOT_INSTALL}" \
    DEFINES="${DEFINES}" \
    UTILS="${UTILS}" \
    $DO _RUN_SCRIPT "${BOOTSTRAP_MODULE_POST}"      || die "_RUN_SCRIPT ${BOOTSTRAP_MODULE_POST} died: $!"
}


##
# rec_bootstrap_module module_name
#
# Clone into a given dir the reference repository
# for a given module

# rec_bootstrap_module module_name
# 
function rec_bootstrap_module () {
    module_name="$1"

    [ -z "${module_name}" ] && die "[rec_bootstrap_module] Usage: rec_bootstrap_module <module_name>"

    # 1. Get the repository name and the branch name to fetch
    for submodule in ${MODULES["${module_name}"]}
    do
        set ${INITIAL_RELEASE["${submodule}"]}
        if [ $# -eq 3 ]
        then
            eval "install_dir=$3"   # for possible ~ expansion
            pushd . &> /dev/null
            $DO bootstrap_module "${submodule}" "$1" "$2" "${install_dir}"
            popd &> /dev/null
        fi
    done
}
    
