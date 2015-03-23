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

# cd to the root repository
#

#----------------------------------------
# BEGIN
#----------------------------------------
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"
cd "$(dirname "$0")"
source ".utils.sh"

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
    # PRE Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_pre "${SCRIPTNAME}" "${module_name}")" "${module_name}"

    #--------------------
    # Install module
    #--------------------
    # Get specs
    module_specs="$(get_module_specs "${module_name}")"
    set ${module_specs}
    git_repos_name="$1"
    git_branch_name="$2"
    install_dir="$3"

    # Check install_dir 
    if [ -d "${install_dir}" ]
    then
        nodir_flag=
    else
        nodir_flag=1
    fi

    # Retrieve and install remote branch into "install_dir"
    if [ -n "${nodir_flag}" ]
    then # Recipient directory does not not exists : good !
        $DO $GIT clone --branch "${git_branch_name}" "$( git_url "${git_repos_name}" )" "${install_dir}"   \
            || die "[bootstrap_module] Cannot git clone:[${git_repos_name}/${git_branch_name}] into:["${install_dir}"] ($!)"

        # Transfer ownership to WWW
        chown -R "${WWWUID}:${WWWGID}" "${install_dir}"

    else # Recipient directory exists and may not be empty : not so good...

        # Create a .gitignore with everything present into it
        ls -A > .gitignore

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
}

##
# _install_submodules module_name
#
# Recurs over module's submodules
# 
function _install_submodules () {
    module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_submodules module_name"

    #--------------------
    # MID Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_mid "${SCRIPTNAME}" "${module_name}")" "${module_name}"

    #--------------------
    # Submodules Install
    #--------------------
    submodules_list="$(get_submodules_list "${module_name}")"
    for submodule in ${submodules_list}
    do
        # recurse
        $DO _RUN_SCRIPT "${SCRIPTFQN}" "${submodule}"
    done

    #--------------------
    # POST Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_post "${SCRIPTNAME}" "${module_name}")" "${module_name}"
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
    module_name="$1"
    [ -z "${module_name}" ] && die "[main] Usage: $SCRIPTNAME module_name"

    if [ "${module_name}" == '-bootstrap' ] 
    then
        # 2nd stage boostrap only
        top_module_name="$(get_topmodule)"
        _install_submodules "${top_module_name}"
    else
        # Full 5 stages install
        _install_module     "${module_name}"
        _install_submodules "${module_name}"
    fi
}

main "$@"
