# utils.sh -- Bash toolbox for local bash-based utilities
#
# PROJECT: MUTINY Tahiti's websites
#
# File to be SOURCED, not ran directly
#
# LIBEXEC must be defined or taken as . as default
#
# Copyright (C) 2014-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés

#----------------------------------------
# CLEAN ENV
#----------------------------------------
[ -z "${LIBEXEC}" ]     && LIBEXEC="$(pwd)"                 # $(pwd) because at this stage we must be positionned
                                                            # INSIDE the libexec directory by the caller, 
                                                            # who is supposed to have done a cd $(dirname $0)
[ -z "${LIBDATA}" ]     && LIBDATA="${LIBEXEC}/../libdata"
[ -z "${DEFINES}" ]     && DEFINES="${LIBEXEC}/DEFINES"
[ -z "${UTILS}" ]       && UTILS="${LIBEXEC}/utils.sh"
[ -z "${CONF}" ]        && CONF="${LIBEXEC}/conf"
export LIBEXEC LIBDATA DEFINES UTILS CONF

PATH="${LIBEXEC}:/usr/local/mysql/bin:/opt/local/lib/mysql56/bin:/opt/local/sbin:/opt/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/X11/bin"
export PATH


#----------------------------------------
# DEBUG
#----------------------------------------
function log () {
    local msg="[$SCRIPTFQN (~$(pwd))] --> $*"
    #logger -s -t "$SCRIPTNAME" "$msg"
}

function trace () {
    local msg="[$SCRIPTFQN (~$(pwd))] --> $*"
    echo "$msg" 1>&2
}

function logtrace () {
    log   "$*"
    trace "$*"
}

function die () {
    local msg="[ERROR::$SCRIPTFQN (~$(pwd))] $*. Aborting!"
    echo "$msg" 1>&2
    logger -s -t "$SCRIPTNAME" "$msg"
    exit 1
}

function do () {
	echo "DO: $*" 1>&2
	"$@"
}

function do_trace () {
    trace "$*"
	"$@"
}

function do_log () {
    log "$*"
    "$@"
}

function do_logtrace () {
    logtrace "$*"
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
#DO=do
#DO=do_continue
#DO=do_trace
#DO=do_log
DO=do_logtrace


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
    die "Unknown command: ${cmd} [$*]"
}

##
# TOOLS NEEDED
#
__bootstrap APACHECTL apachectl __apachectl
    function __apachectl () {
        __nocmd apachectl "$*"
    }

__bootstrap AWK awk __awk
    function __awk () {
        __nocmd awk "$*"
    }

__bootstrap BASH bash __bash
    function __bash () {
        __nocmd bash "$*"
    }

__bootstrap CURL curl __curl
    function __curl () {
        __nocmd curl "$*"
    }

__bootstrap DIFF diff __diff
    function __diff () {
        __nocmd diff "$*"
    }

__bootstrap GIT git __git
    function __git () {
        __nocmd git "$*"
    }

__bootstrap GREP grep __grep
    function __grep () {
        __nocmd grep "$*"
    }

__bootstrap MYSQL mysql __mysql
    function __mysql () {
        __nocmd mysql "$*"
    }

__bootstrap MYSQLDUMP mysqldump __mysqldump
    function __mysqldump () {
        __nocmd mysqldump "$*"
    }

__bootstrap PERL perl __perl
    function __perl () {
        __nocmd perl "$*"
    }

__bootstrap REALPATH realpath __realpath
    function __realpath () {
        echo "$1"
    }

__bootstrap SED sed __sed
    function __sed () {
        __nocmd sed "$*"
    }

__bootstrap TAR tar __tar
    function __tar () {
        __nocmd tar "$*"
    }

__bootstrap UNZIP unzip __unzip
    function __unzip () {
        __nocmd unzip "$*"
    }


#----------------------------------------
# LOAD DEFINITIONS
#----------------------------------------
if [ -e "${DEFINES}" ]
then
    source "${DEFINES}"
else
    die "[${UTILS} Cannot locate mandatory dependancy:[${DEFINES}]"
fi


#----------------------------------------
# SCRIPT LAUNCHER
#----------------------------------------
function _RUN_SCRIPT () {
    local script="$1"; shift

    if [ -e "${script}" ]
    then
        if [ -x "${script}" ] 
        then
            LIBDATA="${LIBDATA}"        \
            LIBEXEC="${LIBEXEC}"        \
            DEFINES="${DEFINES}"        \
            UTILS="${UTILS}"            \
            CONF="${CONF}"              \
                $DO "${script}" "$@"
        else 
            LIBDATA="${LIBDATA}"        \
            LIBEXEC="${LIBEXEC}"        \
            DEFINES="${DEFINES}"        \
            UTILS="${UTILS}"            \
            CONF="${CONF}"              \
                $DO $BASH "${script}" "$@"
        fi
    fi
}


#----------------------------------------
# EXEC SCRIPT
#----------------------------------------
function _EXEC_SCRIPT () {
    local script="$1"; shift

    if [ -e "${script}" ]
    then
        if [ -x "${script}" ] 
        then
            LIBDATA="${LIBDATA}"        \
            LIBEXEC="${LIBEXEC}"        \
            DEFINES="${DEFINES}"        \
            UTILS="${UTILS}"            \
            CONF="${CONF}"              \
                $DO exec "${script}" "$@"
        else 
            LIBDATA="${LIBDATA}"        \
            LIBEXEC="${LIBEXEC}"        \
            DEFINES="${DEFINES}"        \
            UTILS="${UTILS}"            \
            CONF="${CONF}"              \
                $DO exec $BASH "${script}" "$@"
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
    [ $# -lt 3 ] && die "Invalid module spec:[$specs]"
    local repos_name="$1"
    local branch_name="$2"
    eval "module_dir=$3"       # for possible ~ expansion
    eval "install_dir=$4"   # for possible ~ expansion
    [ -z "${install_dir}" ] && install_dir="${module_dir}"
    echo "${repos_name}" "${branch_name}" "${module_dir}" "${install_dir}"
}

##
# module_dir=$(get_module_dir module_name)
#
function get_module_dir () {
    local module_name="$1"
    local module_specs="$(get_module_specs "${module_name}")"
    set ${module_specs}
    echo "$3"
}

##
# top_module=$(get_topmodule)
#
function get_topmodule () {
    echo "${MODULES[root]}"
}

##
# parent_module=$(get_parentmodule)
#
function get_parentmodule () {
    echo "${PARENT_MODULE[$1]}"
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
# Download a zipball from a github repository and installs it
#
# install_git_distribution module
#function install_git_distribution () {
#    local module_name="$1"
#
#    [ -z "${module_name}" ] && die "[install_git_distribution] Usage: install_git_distribution <module_name>"
#
#    set ${INITIAL_RELEASE["${module_name}"]}
#    [ $# -ne 3 ] && die "[install_git_distribution] Invalid git module specification:[${INITIAL_RELEASE["${module_name}"]}]"
#
#    local repos_name="$1"
#    local branch_name="$2"
#    eval "install_dir=$4"   # for possible ~ expansion
#
#    local zipdirname="${repos_name}-${branch_name}"
#    local zipfile="${repos_name}-${branch_name}.zip"
#
#    # 2. Fetch the stuff
#    $CURL -s -f -C - --retry 9 --retry-delay 5 -o "${zipfile}"  "https://codeload.github.com/franckporcher/${repos_name}/zip/${branch_name}"
#    if [ -s "${zipfile}" ]
#    then
#        # Create the recipient directory, unless it exists
#        [ ! -d "${install_dir}" ] && mkdir -p "${install_dir}"
#
#        # The zip archive comprises one directory named ${repos_name}-${branch_name}
#        # We must extract the content of this dir into the install_dir
#        # instead of creating that dir into the current dir
#        # We do the trick by creating a symbolink on the recipient, so the
#        # archive will decompress into it ;)
#        ln -s "${install_dir}" "${zipdirname}"
#        $UNZIP -q -o -d . "${zipfile}"
#        rm "${zipdirname}"
#        rm "${zipfile}"
#    fi
#}


#----------------------------------------
# INSTALL CONFIG FILES
#----------------------------------------
function install_config_files () {
    local module_name="$1"
    [ -z "$module_name" ] && die "Usage: install_config_files <module_name>"

    local tag
    local op
    local src_file
    local dst_file
    local mode_file
    local uid_file
    local gid_file
    local force
    local specs     # OP SRC DEST MODE UID GID

    for tag in ${CONFIG["${module_name}"]}
    do
        specs="${CONFIG["${tag}"]}"
        set $specs
        op="$1"
        src_file="$2" 
        dst_file="$3" 
        mode_file="$4"; [ -z "$mode_file" ] && mode_file='640'
        uid_file="$5";  [ -z "$uid_file"  ] && uid_file="${WWWUID}"
        gid_file="$6";  [ -z "$gid_file"  ] && gid_file="${WWWGID}"
        force="$7";

        $DO install_one_config_file "${op}" "${CONF}/${src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" "${force}"
    done
}

# install_one_config_file OP SRC DEST MOD UID GID FORCE
function install_one_config_file () {
    local op="$1"
    local src_file="$2"
    local dst_file="$3"
    local mode_file="$4"
    local uid_file="$5"
    local gid_file="$6"
    local force="$7"

    local ownership
    [ "${uid_file}" != '-' ] && ownership="${uid_file}"
    [ "${gid_file}" != '-' ] && ownership="${ownership}:${gid_file}"


    # Check local file exists
    [ ! -e "${src_file}" ] && die "[install_one_config_file] Source file:[${src_file}] does not exist."

    # Check dest dir
    local dst_dir="$(dirname "${dst_file}")"
    if [ ! -d "${dst_dir}" ]
    then
        if [ -z "${force}" ]
        then
            $DO mkdir -p "${dst_dir}"
            $DO chmod 750 "${dst_dir}"
            [ -n "${ownership}" ] && $DO chown "${ownership}" "${dst_dir}"
        else
            die "[install_one_config_file] Destination directory:[${dst_dir}] does not exist."
        fi
    fi

    # Check dest file
    case "${op}" in
        install)
            if [ -e "${dst_file}" ]
            then
                # File already exists (do not touch mode and ownership) 
                # Install new version iff new version differs !
                $DIFF "${src_file}" "${dst_file}" &> /dev/null || $DO cp "${src_file}" "${dst_file}" 
            else
                # File does not exit. Simply installs it
                $DO cp "${src_file}" "${dst_file}" 
                $DO chmod "${mode_file}" "${dst_file}"
                [ -n "${ownership}" ] && $DO chown "${ownership}" "${dst_file}"
            fi
            ;;

        append)
            # Compute non blank lines from src_file that are not into dst_file
            # and push them onto dst_file.

            if [ -e "${dst_file}" ]
            then
                ### Slow version, using temporary files
                #local file_A="/tmp/__tmp_A_$(date "+%s")"
                #local file_B="/tmp/__tmp_B_$(date "+%s")"
                #cat "${src_file}" | sed '/^[[:space:]]*$/d' > "${file_A}"
                #cat "${dst_file}" | sed '/^[[:space:]]*$/d' > "${file_B}"
                #$DO grep -F -x -v -f "${file_B}" "${file_A}" >> "${dst_file}"
                #$DO rm -f "${file_B}" "${file_A}"

                ### Fast version, using process substitution and named pipes
                ### Bash 4
                $DO $GREP -F -x -v -f \
                    <(cat "${dst_file}" | $SED '/^[[:space:]]*$/d') \
                    <(cat "${src_file}" | $SED '/^[[:space:]]*$/d') \
                    >> "${dst_file}"
            else
                # File does not exit. Simply installs it
                $DO cp "${src_file}" "${dst_file}" 
                $DO chmod "${mode_file}" "${dst_file}"
                [ -n "${ownership}" ] && $DO chown "${ownership}" "${dst_file}"
            fi
            ;;

        'tmpl.install')
            local expanded_src_file="$(tmpl_expand_file "${src_file}")"
            [ $? -ne 0 -o -z "${expanded_src_file}" ] && exit 1

            $DO install_one_config_file install "${expanded_src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" ${force}
            rm -f "${expanded_src_file}"
            ;;

        'tmpl.append')
            local expanded_src_file="$(tmpl_expand_file "${src_file}")"
            [ $? -ne 0 -o -z "${expanded_src_file}" ] && exit 1

            $DO install_one_config_file append "${expanded_src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" ${force}
            rm -f "${expanded_src_file}"
            ;;

        'sed.install')
            local expanded_src_file="$(sed_expand_file "${src_file}")"
            [ $? -ne 0 -o -z "${expanded_src_file}" ] && exit 1

            $DO install_one_config_file install "${expanded_src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" ${force}
            rm -f "${expanded_src_file}"
            ;;

        'sed.append')
            local expanded_src_file="$(sed_expand_file "${src_file}")"
            [ $? -ne 0 -o -z "${expanded_src_file}" ] && exit 1

            $DO install_one_config_file append "${expanded_src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" ${force}
            rm -f "${expanded_src_file}"
            ;;

        'env.install')
            local expanded_src_file="$(env_expand_file "${src_file}")"
            [ $? -ne 0 -o -z "${expanded_src_file}" ] && exit 1

            $DO install_one_config_file install "${expanded_src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" ${force}
            rm -f "${expanded_src_file}"
            ;;

        'env.append')
            local expanded_src_file="$(env_expand_file "${src_file}")"
            [ $? -ne 0 -o -z "${expanded_src_file}" ] && exit 1

            $DO install_one_config_file append "${expanded_src_file}" "${dst_file}" "${mode_file}" "${uid_file}" "${gid_file}" ${force}
            rm -f "${expanded_src_file}"
            ;;

        *)  die "[install_one_config_file] Unknown operator:[$op] on [$*]"
            ;;
    esac
}


function tmpl_expand_file () {
    local src_file="$1"
    [ ! -e "${src_file}" ] && die "[tmpl_expand_file] Cannot locate file:[${src_file}]"

    local file_C="/tmp/__tmp_C_$(date "+%s")"
    local file_D="/tmp/__tmp_D_$(date "+%s")"

    cat "${src_file}" | $SED -e 's/"/\\"/g' -e 's/^/echo "/' -e 's/$/"/' > "${file_D}"

    cat <<-EOT > "${file_C}"
$(source  "${file_D}")
EOT

    rm -f "${file_D}"

    echo "${file_C}"
}

function sed_expand_file () {
    local src_file="$1"
    [ ! -e "${src_file}" ] && die "[sed_expand_file] Cannot locate file:[${src_file}]"

    local sed_cmd_file="${src_file}.sed"
    [ ! -e "${sed_cmd_file}" ] && die "[sed_expand_file] Cannot locate sed command file:[${sed_cmd_file}]"

    # 1. Expand  sed_cmd_file
    local expanded_sed_cmd_file="$(tmpl_expand_file "${sed_cmd_file}")"

    # 2. Apply sed commands
    local file_E="/tmp/__tmp_E_$(date "+%s")"
    $SED -E -f "${expanded_sed_cmd_file}" "${src_file}" > "${file_E}"

    rm "${expanded_sed_cmd_file}"

    echo "${file_E}"
}

# ${__ENV_VAR_NAME__} -> valeur de la variable d'environnement
function env_expand_file () {
    local src_file="$1"
    [ ! -e "${src_file}" ] && die "[env_expand_file] Cannot locate file:[${src_file}]"

    # 2. Apply sed commands
    local file_E="/tmp/__tmp_E_$(date "+%s")"
    cat "${src_file}" | $PERL -pe 's/\$\{__(.*?)__\}/$ENV{$1}/sge' > "${file_E}"

    echo "${file_E}"
}

