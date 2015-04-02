#!/bin/bash
#
# install_module.sh module_name
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
cd "$(dirname "$0")"    # cd into libexeec
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"

[ -z "${UTILS}" ] && UTILS="$(pwd)/utils.sh"
if [ -e "${UTILS}" ]
then
    source "${UTILS}"
else
    msg="[ERROR::$SCRIPTFQN (~$(pwd))] Cannot locate mandatory dependancy: ${UTILS}. Aborting!"
    echo "$msg" 1>&2
    logger -s -t "$SCRIPTNAME" "$*"
    exit 1
fi

##
# _install_module module_name
#
# Clone into a given dir the reference repository
# for a given module
# 
function _install_module () {
    module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module module_name"

    #--------------------
    # Module Specs
    #--------------------
    local module_specs="$(get_module_specs "${module_name}")"
    set ${module_specs}
    local git_repos_name="$1"
    local git_branch_name="$2"
    local module_dir="$3"
    local install_dir="$4"

    #--------------------
    # PRE Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_pre "${SCRIPTNAME}" "${module_name}")" "${module_name}" "${module_dir}"

    #--------------------
    # Pre-install module
    # in its own directory
    #--------------------
    $DO $GIT clone --branch "${git_branch_name}" "$( git_url
    "${git_repos_name}" )" "${module_dir}"   \
    || die "[bootstrap_module] Cannot git clone:[${git_repos_name}/${git_branch_name}] into:["${module_dir}"] ($!)"

    # Transfer ownership to WWW
    $DO chown -R "${WWWUID}:${WWWGID}" "${module_dir}"

    #--------------------
    # Install to the definite
    # install dir
    #--------------------
    if [ "${module_dir}" != "${install_dir}" ]
    then
        #---- VERSION 1 -----
        # Clone in a clean dir and move everything to the recipient dir
        # Creates overlapping problem if the recipient dir is already a git
        # repository. Not good
        #--------------------
        # Create a .gitignore comprised of everything existing in that directory
        # ls -A "${install_dir}" > "${install_dir}/.gitignore"

        # Move everything into install directory
        # mv ${module_dir}/*      "${install_dir}"
        # mv ${module_dir}/.[!.]* "${install_dir}"

        #---- VERSION 2 -----
        # Clone in a clean dir and links everything but git stuff into the recipient dir
        # Better
        #--------------------
        # Link everything into install directory
        pushd "${module_dir}"
        local pwd="$(pwd)"

        { 
            local modfile
            local target

            while read modfile
            do
                target="${install_dir}/${modfile}"
                if [ ! -e "${target}" -a ! -h "{$target}" ]
                then
                    ln -s "${pwd}/${file}" "${target}"
                fi
            done
        } < <$(ls -A | grep -v -F '.git')  

        popd
    fi
}

##
# _install_submodules module_name
#
# Recurs over module's submodules
# 
function _install_submodules () {
    local module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_submodules module_name"

    #--------------------
    # Module Specs
    #--------------------
    local module_dir="$(get_module_dir "${module_name}")"

    #--------------------
    # MID Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_mid "${SCRIPTNAME}" "${module_name}")" "${module_name}" "${module_dir}"

    #--------------------
    # Submodules Install
    #--------------------
    local submodules_list="$(get_submodules_list "${module_name}")"
    for submodule in ${submodules_list}
    do
        # recurse
        $DO _RUN_SCRIPT "${SCRIPTFQN}" "${submodule}"
    done

    #--------------------
    # POST Install
    #--------------------
    install_config_files "${module_name}"
    $DO _RUN_SCRIPT "$(get_post "${SCRIPTNAME}" "${module_name}")" "${module_name}" "${module_dir}"
}

#----------------------------------------
# MAIN
# 
#   5 Stages module installation :
#
#   . PRE-INSTALL           (modules/<modulename>/install_module.pre.sh)
#   . GIT INSTALL
#   . MID-INSTALL           (modules/<modulename>/install_module.mid.sh)
#   . SUBMODULES INSTALL
#   . POST-INSTALL          (modules/<modulename>/install_module.post.sh)
#
#----------------------------------------
# To be called with -bootstrap for initial install from a boostrap stub
function main() {
    local module_name="$1"
    [ -z "${module_name}" ] && die "[main] Usage: $SCRIPTNAME module_name"

    if [ "${module_name}" == '-bootstrap' ] 
    then
        # 2nd stage boostrap only
        local top_module_name="$(get_topmodule)"
        ${DO} _install_submodules "${top_module_name}"
    else
        # Full 5 stages install
        ${DO} _install_module     "${module_name}"
        ${DO} _install_submodules "${module_name}"
    fi
}

${DO} main "$@"
