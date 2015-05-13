#!/bin/bash
#
# reinstall_module.sh module_name | -bootstrap OPTIONS
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 2014-2015 - Franck Porcher, Ph.D 
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
# _prereinstall module_name module_dir
#
# PRE-REINSTALL PHASE for a given module
# 
function _prereinstall_module () {
    module_name="$1";
     module_dir="$2";
    [ -z "${module_name}" ] && die "Usage: _prereinstall_module module_name module_dir"

    #--------------------
    # PRE Reinstall
    #--------------------
    local prereinstall="$(get_prere "${SCRIPTNAME}" "${module_name}")"
    if [ -e "${prereinstall}" ]
    then
        $DO _RUN_SCRIPT "${prereinstall}" "${module_name}" "${module_dir}"
    else
        return 0
    fi
}


##
# _postreinstall module_name module_dir
#
# POST-REINSTALL PHASE for a given module
# 
function _postreinstall_module () {
    module_name="$1";
     module_dir="$2";
    [ -z "${module_name}" ] && die "Usage: _postreinstall_module module_name module_dir"

    #--------------------
    # PRE Reinstall
    #--------------------
    local postreinstall="$(get_postre "${SCRIPTNAME}" "${module_name}")"
    if [ -e "${postreinstall}" ]
    then
        $DO _RUN_SCRIPT "${postreinstall}" "${module_name}" "${module_dir}"
    else
        return 0
    fi
}


function _trace_in () {
    local module_name step
    module_name="$1"
    step="$2"
    
    {
        echo
        echo "========[Installing module:${module_name^^*}]====[STARTING ${step^^*}]=============================================================" 
    } 1>&2
}


function _trace_out () {
    local module_name step
    module_name="$1"
    step="$2"
    
    {
        echo "========[Installing module:${module_name^^*}]====[END ${step^^*}]=============================================================" 
        echo
    } 1>&2
}


#----------------------------------------
# MAIN OPTIONS module_name...
# 
#   9 Stages module reinstallation :
#
#   . PRE REINSTALL         (modules/<modulename>/reinstall_module.pre.sh)
#   . PRE INSTALL           (modules/<modulename>/install_module.pre.sh)
#   . GIT FETCH
#   . GIT INSTALL
#   . MID INSTALL           (modules/<modulename>/install_module.mid.sh)
#   . CONFIG
#   . SUBMODULES REINSTALL
#   . POST INSTALL          (modules/<modulename>/install_module.post.sh)
#   . POST REINSTALL        (modules/<modulename>/reinstall_module.post.sh)
#
# OPTIONS
#   -a --all            --all
#   -none           --none
#   -prereinstall   --nopreinstall
#   -preinstall     --preinstall
#   -fetch          --fetch
#   -install        --install
#   -midinstall     --midinstall
#   -config         --config
#   -submodules     --submodules
#   -postinstall    --postinstall
#   -nopreinstall   --nopreinstall
#   -nofetch
#   -noinstall
#   -nomidinstall
#   -noconfig
#   -nosubmodules
#   -nopostinstall
#   -nopostreinstall
#
#   -d              --dryrun
#   -l -list        --list
#   -m              --listsubmodules
#
#----------------------------------------

OPTIONS=(prereinstall preinstall fetch install midinstall config submodules postinstall postreinstall)

declare -A OPTIONS_CODE
OPTIONS_CODE[prereinstall]=0
OPTIONS_CODE[preinstall]=1
OPTIONS_CODE[fetch]=2
OPTIONS_CODE[install]=3
OPTIONS_CODE[midinstall]=4
OPTIONS_CODE[config]=5
OPTIONS_CODE[submodules]=6
OPTIONS_CODE[postinstall]=7
OPTIONS_CODE[postreinstall]=8

function main() {
    local module_name="$1"; shift;
    [ -z "${module_name}" ] && die "[main] Usage: $SCRIPTNAME module|-bootstrap OPTIONS"
    _trace_in "$module_name" 

    local cmds=()
    local opt
    local dryop
    local listsubmodules
    local module_dir
    local cmd

    # Handle OPTIONS
    for opt in "$@"
    do
        case "$opt" in 
            -d    | --dryrun    ) dryop=1
                ;;

            -m |  --list-submodules ) listsubmodules=1
                ;;
            
            -none | --none      ) cmds=()
                ;;
            
            -a | -all | --all   ) cmds=( "${OPTIONS[@]}" )
                ;;

            --no*               ) opt=${opt#'--no'}
                                  # remove command
                                  if [ -n "${OPTIONS_CODE["$opt"]}" ]
                                  then
                                    cmds[ ${OPTIONS_CODE["$opt"]} ]=''
                                  fi
                                  ;;
            
            -no*                ) opt=${opt#'-no'}
                                  # remove command
                                  if [ -n "${OPTIONS_CODE["$opt"]}" ]
                                  then
                                     cmds[ ${OPTIONS_CODE["$opt"]} ]=''
                                  fi
                                  ;;

            --*                 ) opt=${opt#'--'}
                                  # Add command
                                  if [ -n "${OPTIONS_CODE["$opt"]}" ]
                                  then
                                    cmds[ ${OPTIONS_CODE["$opt"]} ]="$opt"
                                  fi
                                  ;;

            -*                  ) opt=${opt#'-'}
                                  # Add command
                                  if [ -n "${OPTIONS_CODE["$opt"]}" ]
                                  then
                                    cmds[ ${OPTIONS_CODE["$opt"]} ]="$opt"
                                  fi
                                  ;;
        esac
    done


    ##
    # CHECK FOR NOMODULE
    #
    if [ "${module_name}" == '-bootstrap' ] 
    then
        module_name="$(get_topmodule)"
    elif [ -z "${IS_MODULE["${module_name}"]}" ]
    then
        logtrace "[main] Module:[$module_name] - Not a module"
        _trace_out "$module_name" 
        return 1
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
        _trace_out "$module_name" 
        return 0
    fi


    ##
    # LIST MODULE'S SUBMODULES
    #
    if [ -n "$listsubmodules" ]
    then
        local submodules_list="$(get_submodules_list "${module_name}")"

        for i in $(ls ${stage_mark}* )
        do
            stages_done="$stages_done ${i#$stage_mark}"
        done

        if [ -z "$submodules_list" ] 
        then
            ${DO} echo "[main] [LIST] Module:[$module_name] has no sub-module"
        else
            ${DO} echo "[main] [LIST] Module:[$module_name] sub-modules:[$submodules_list]"
        fi
        _trace_out "$module_name" 
        return 0
    fi


    ##
    # RUN COMMANDS
    #
    local  do_prereinstall_flag="${cmds[ ${OPTIONS_CODE["prereinstall"]}  ]}"
    local do_postreinstall_flag="${cmds[ ${OPTIONS_CODE["postreinstall"]} ]}"
    cmds[ ${OPTIONS_CODE["prereinstall"]}  ]=''
    cmds[ ${OPTIONS_CODE["postreinstall"]} ]=''

    # Cas particulier for TOP module
    local reinstall_script
    if [ "${module_name}" == "$(get_topmodule)" ]
    then
        cp "${LIBEXEC}/bootstrap.local.sh" /tmp
        reinstall_script="/tmp/bootstrap.local.sh"
    else
        reinstall_script="${LIBEXEC}/install_module.sh"
    fi


    # 1. prereinstall
    if [ -n "${do_prereinstall_flag}" ]
    then
        _prereinstall_module "${module_name}" "${module_dir}" || {
            local cr="$?"
            _trace_out "$module_name" 
            return "$cr"
        }
    fi
    if [ -d "${module_dir}" ]
    then
        rm -rf "${module_dir}"
    fi

    # 2. Reinstall module
    local options
    for opt in "${cmds[@]}"
    do
        options="${options} --${opt}"
    done
    $DO _RUN_SCRIPT "${reinstall_script}" "${module_name}" $options

    # 3. postreinstall
    if [ -n "${do_postreinstall_flag}" ]
    then
        _postreinstall_module "${module_name}" "${module_dir}" || {
            local cr="$?"
            _trace_out "$module_name" 
            return "$cr"
        }
    fi

    # 4. The end - that's all folks !
    _trace_out "$module_name" 
}

if [ $# -lt 1 ]
then
    cat <<-EOT

    USAGE: $SCRIPTNAME {MODULE-NAME | -bootstrap} [OPTIONS]

    OPTIONS:
        -d              --dryrun        # Tell what will be done but do not run it
        -m              --list-modules  # List module's submodules

        -a -all         --all           # Run all reinstallation / installation stages
        -none           --none          # Run none (default)

        -prereinstall   --prereinstall  # Prereinstall stage
        -preinstall     --preinstall    # Preinstall stage
        -fetch          --fetch         # Fetch the module on GitHub
        -install        --install       # Installs it to its final destination
        -midinstall     --midinstall    # Custom mid-install stage
        -config         --config        # Install/Tune configuration files
        -submodules     --submodules    # Install submodules
        -postinstall    --postinstall   # Post-install  stage
        -postreinstall  --postreinstall # Post-install  stage

        -noprereinstall  --noprereinstall
        -nopreinstall    --nopreinstall
        -nofetch         --nofetch
        -noinstall       --noinstall
        -nomidinstall    --nomidinstall
        -noconfig        --noconfig
        -nosubmodules    --nosubmodules
        -nopostinstall   --nopostinstall
        -nopostreinstall --nopostreinstall
EOT

else
    ${DO} main "$@"
fi
        

