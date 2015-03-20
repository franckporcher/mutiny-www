#!/bin/bash
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved


## WEB SERVER ID
WWW_USER=www
WWW_GUSER=www

## MUTINY PRESTASHOP
MUTINY_WWW_PS=store

## MUTINY PRESTASHOP
MUTINY_WWW_CGM=cgm

##
ROOT_DIR=..


BOOTSTRAP=update-modules.sh
DEPENDANCIES=../management/dependancies.sh


# 
# cd to the root repository
#
function cd_root () {
    cd "$(dirname "$0")"
    [ -e "${DEPENDANCIES}" ] && source "${DEPENDANCIES}"
}

function test () {
    echo "Hello, this is '$0' from '$(pwd)'"
}

function install_submodule () {
    :   # Place holder for actual work
}


#
# main
#
function main() {
    cd_root
    test
    install_submodule

}

main "$@"
