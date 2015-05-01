#!/bin/bash
#
# install_module.sh MAIN {module_name | -bootstrap} OPTIONS
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
# _install_module_preinstall module_name
#
# PRE-INSTALL PHASE for a given module
# 
function _install_module_preinstall () {
    module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_preinstall module_name"

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
}


##
# _install_module_fetch module_name
#
# FETCH THE MODULE FROM THE GITHUB REPOSITORY
# 
function _install_module_fetch () {
    module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_fetch module_name"

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
    # FETCH MODULE IN ITS
    #   OWN DIRECTORY
    #--------------------
    $DO $GIT clone --branch "${git_branch_name}" "$( git_url "${git_repos_name}" )" "${module_dir}"   \
      || die "[install_module_fetch] Cannot git clone:[${git_repos_name}/${git_branch_name}] into:["${module_dir}"] ($!)"
}


##
# _install_module_install module_name
#
# INSTALL OF THE MODULE
# 
function _install_module_install () {
    module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_install module_name"

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
    # Install to the definite
    # install dir
    #--------------------

    # Transfer ownership to WWW : CASE BY CASE IN MID/POST CUSTOM INSTALL
    # $DO chown -R "${WWWUID}:${WWWGID}" "${module_dir}"

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
            local module_file
            local src
            local link

            while read module_file
            do
                src="${pwd}/${module_file}"
                link="${install_dir}/${module_file}"
                if [ ! -e "${link}" -a ! -h "${link}" ]
                then
                    ln -s "${src}" "${link}"
                fi
            done
        } < <(ls -A | grep -v -F '.git')  

        popd
    fi
}


##
# _install_module_midinstall module_name
#
# MID-INSTALLATION PHASE
#
function _install_module_midinstall () {
    local module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_midinstall module_name"

    #--------------------
    # Module Specs
    #--------------------
    local module_dir="$(get_module_dir "${module_name}")"

    #--------------------
    # MID Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_mid "${SCRIPTNAME}" "${module_name}")" "${module_name}" "${module_dir}"
}


##
# _install_module_config module_name
#
# INSTALL CONFIGURATION FILES FOR MODULE
# 
function _install_module_config () {
    local module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_config module_name"

    #--------------------
    # Module Specs
    #--------------------
    local module_dir="$(get_module_dir "${module_name}")"

    #--------------------
    # Configuration files
    # installation
    #--------------------
    install_config_files "${module_name}"
}


##
# _install_module_submodules
#
# SUB-MODULES INSTALLATION
# 
function _install_module_submodules () {
    local module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_submodules module_name"

    #--------------------
    # Module Specs
    #--------------------
    local module_dir="$(get_module_dir "${module_name}")"

    #--------------------
    # Submodules Install
    #--------------------
    local submodules_list="$(get_submodules_list "${module_name}")"
    for submodule in ${submodules_list}
    do
        # recurse
        $DO _RUN_SCRIPT "${SCRIPTFQN}" "${submodule}" --all
    done
}


##
# _install_module_postinstall module_name
#
# POST-INSTALLATION PHASE
# 
function _install_module_postinstall () {
    local module_name="$1"; shift
    [ -z "${module_name}" ] && die "Usage: _install_module_postinstall module_name"

    #--------------------
    # Module Specs
    #--------------------
    local module_dir="$(get_module_dir "${module_name}")"

    #--------------------
    # POST Install
    #--------------------
    $DO _RUN_SCRIPT "$(get_post "${SCRIPTNAME}" "${module_name}")" "${module_name}" "${module_dir}"
}


#----------------------------------------
# MAIN {module_name | -bootstrap} OPTIONS
# 
#   7 Stages module installation :
#
#   . PRE INSTALL           (modules/<modulename>/install_module.pre.sh)
#   . GIT FETCH
#   . GIT INSTALL
#   . MID INSTALL           (modules/<modulename>/install_module.mid.sh)
#   . CONFIG
#   . SUBMODULES INSTALL
#   . POST INSTALL          (modules/<modulename>/install_module.post.sh)
#
# OPTIONS
#   -a --all            --all
#   -none           --none
#   -preinstall     --preinstall
#   -fetch          --fetch
#   -install        --install
#   -midinstall     --midinstall
#   -config         --config
#   -submodules     --submodules
#   -postinstall    --postinstall
#   -nopreinstall   --nopreinstall
#   -nofetch        --nofetch
#   -noinstall      --noinstall
#   -nomidinstall   --nomidinstall
#   -noconfig       --noconfig
#   -nosubmodules   --nosubmodules
#   -nopostinstall  --nopostinstall
#
#   -d              --dryrun
#   -l -list        --list
#
#----------------------------------------
# To be called with -bootstrap -all for initial install from a boostrap stub

OPTIONS=(preinstall fetch install midinstall config submodules postinstall)

declare -A OPTIONS_CODE
OPTIONS_CODE[preinstall]=0
OPTIONS_CODE[fetch]=1
OPTIONS_CODE[install]=2
OPTIONS_CODE[midinstall]=3
OPTIONS_CODE[config]=4
OPTIONS_CODE[submodules]=5
OPTIONS_CODE[postinstall]=6

function main() {
    local module_name="$1"
    shift

    [ -z "${module_name}" ] && die "[main] Usage: $SCRIPTNAME module_name|-bootstrap OPTIONS"

    local module_dir
    local cmds=()
    local listop
    local dryop
    local opt
    local cmd
    local stage_mark

    # Handle OPTIONS
    for opt in "$@"
    do
        case "$opt" in 
            -d    | --dryrun    ) dryop=1
                ;;
            -l | -list | --list ) listop=list
                ;;
            -none | --none      ) cmds=()
                ;;
            -a | -all | --all   ) cmds=( "${OPTIONS[@]}" )
                ;;
                    --no*       ) opt=${opt#'--no'}
                                  # remove command
                                  cmds[ ${OPTIONS_CODE["$opt"]} ]=''
                                  ;;
            -no*                ) opt=${opt#'-no'}
                                  # remove command
                                  cmds[ ${OPTIONS_CODE["$opt"]} ]=''
                                  ;;
                    --*         ) opt=${opt#'--'}
                                  # Add command
                                  cmds[ ${OPTIONS_CODE["$opt"]} ]="$opt"
                                  ;;
            -*                  ) opt=${opt#'-'}
                                  # Add command
                                  cmds[ ${OPTIONS_CODE["$opt"]} ]="$opt"
                                  ;;
        esac
    done


    ##
    # CHECK FOR BOOTSTRAP
    #
    if [ "${module_name}" == '-bootstrap' ] 
    then
        module_name="$(get_topmodule)"
        module_dir="$(get_module_dir "${module_name}")"

        touch "${module_dir}/.${module_name}.preinstall"
        touch "${module_dir}/.${module_name}.fetch"

        # 2nd stage boostrap only
        cmds[ ${OPTIONS_CODE["preinstall"]} ]=''
        cmds[ ${OPTIONS_CODE["fetch"]} ]=''
    fi


    ##
    # MODULE DIR
    #
    module_dir="$(get_module_dir "${module_name}")"


    ##
    # DRYRUN
    #
    if [ -n "$dryop" ]
    then
        ${DO} echo "[main] [DRYRUN] Module:[$module_name] - Would run the commands --> $listop ${cmds[*]}"
        return 0
    fi


    ##
    # LIST STAGES ALREADY DONE
    #
    if [ -n "$listop" ]
    then
        stage_mark="${module_dir}/.${module_name}."
        local stages_done
        local i

        for i in $(ls ${stage_mark}* )
        do
            stages_done="$stages_done ${i#$stage_mark}"
        done

        ${DO} echo "[main] [LIST] Module:[$module_name] - Installation stages already performed --> $stages_done"
        return 0
    fi


    ##
    # RUN COMMANDS
    #

    for cmd in "${cmds[@]}"
    do
        stage_mark="${module_dir}/.${module_name}.${cmd}"

        if [ -e "${stage_mark}" ]
        then
            logtrace "[main] Module:[$module_name] - Stage already done: $cmd"
        else
            if ${DO} "_install_module_${cmd}"  "${module_name}"
            then
                touch "${stage_mark}"
            fi
        fi
    done
}

${DO} main "$@"
