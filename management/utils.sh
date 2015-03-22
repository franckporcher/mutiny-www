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
export MUTINY_ROOT_INSTALL

DEFINES="${MUTINY_ROOT_INSTALL}/management/DEFINES"

if [ -e "${DEFINES}" ]
then
    source "${DEFINES}"
else
    die "[ERROR] Cannot locate mandatory dependancy:[${DEFINES}]"
fi

#----------------------------------------
# TOOLS AVAILABILITY CHECKING
#
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
    [ ! -d "${install_dir}" ] && $DO  mkdir -p "${install_dir}"
    $DO cd "${install_dir}" || die "Cannot cd:[${install_dir}] for installing module:[$module_name]"

    # 2. Retrieve remote distribution
    # $GIT_URL="ssh://git@github.com/franckporcher"
    $DO $GIT clone --branch "${git_branch_name}" "$( git_url "${git_repos_name}" )" .

    # 3. REC 
    $DO rec_bootstrap_module "${git_repos_name}"

    # 4. Post bootstrap 
    $DO _RUN_SCRIPT "${BOOTSTRAP_MODULE_POST}"
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

    [ -z "${module_name}" ] && return

    # 1. Get the repository name and the branch name to fetch
    for submodule in ${MODULES["${module_name}"]}
    do
        set ${INITIAL_RELEASE["${module_name}"]}
        if [ $# -eq 3 ]
        then
            pushd . &> /dev/null
            $DO bootstrap_module "${submodule}" "$@"
            popd &> /dev/null
        fi
    done
}
    

