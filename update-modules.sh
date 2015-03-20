#!/bin/bash
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved
#
VERSION="0.1 -- Jeu 19 mar 2015 19:21:18 PDT"


## WEB SERVER ID
WWW_USER=www
WWW_GUSER=www

## MUTINY WORDPRESS
MUTINY_WWW_WP=wordpress

## MUTINY PRESTASHOP
MUTINY_WWW_PS=store

## MUTINY PRESTASHOP
MUTINY_WWW_CGM=cgm


BOOTSTRAP=update-modules.sh
DEPENDANCIES=management/dependancies.sh


# 
# cd to the root repository
#
function cd_root () {
    cd "$(dirname "$0")"
    [ -e "${DEPENDANCIES}" ] && source "${DEPENDANCIES}"
}


function update_mutiny_www_wp () {
    if [ ! -d "${MUTINY_WWW_WP}" ]
    then 
        mkdir -p "${MUTINY_WWW_WP}"
        chown "${WWW_USER}:${WWW_GUSER}" "${MUTINY_WWW_WP}"
        chown "750" "${MUTINY_WWW_WP}"
    fi

    # Boostrap submodule 
    if [ -e "${MUTINY_WWW_WP}/${BOOTSTRAP}" ]
    then
        pushd "${MUTINY_WWW_WP}" &> /dev/null
        "./${BOOTSTRAP}"
        popd &> /dev/null
    fi
}

function update_mutiny_www_ps () {
    if [ ! -d "${MUTINY_WWW_PS}" ]
    then 
        mkdir -p "${MUTINY_WWW_PS}"
        chown "${WWW_USER}:${WWW_GUSER}" "${MUTINY_WWW_PS}"
        chown "750" "${MUTINY_WWW_PS}"
    fi

    # Boostrap submodule 
    if [ -e "${MUTINY_WWW_PS}/${BOOTSTRAP}" ]
    then
        pushd "${MUTINY_WWW_PS}" &> /dev/null
        "./${BOOTSTRAP}"
        popd &> /dev/null
    fi
}

function update_mutiny_www_cgm () {
    if [ ! -d "${MUTINY_WWW_CGM}" ]
    then 
        mkdir -p "${MUTINY_WWW_CGM}"
        chown "${WWW_USER}:${WWW_GUSER}" "${MUTINY_WWW_CGM}"
        chown "750" "${MUTINY_WWW_CGM}"
    fi

    # Boostrap submodule 
    if [ -e "${MUTINY_WWW_CGM}/${BOOTSTRAP}" ]
    then
        pushd "${MUTINY_WWW_CGM}" &> /dev/null
        "./${BOOTSTRAP}"
        popd &> /dev/null
    fi
}



#
# main
#
function main() {
    cd_root
    update_mutiny_www_wp
    update_mutiny_www_ps
    update_mutiny_www_cgm
}

main "$@"
