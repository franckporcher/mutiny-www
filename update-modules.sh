#!/bin/bash
#
# update-modules.sh -- Update MUTINY Tahiti's various modules
#                      from github specifications set
#                      in <siteroot>/management/git-branches.sh
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

ROOT_DIR=.

# 
# cd to the root repository
#
cd "$(dirname "$0")"
source "${ROOT_DIR}/management/git-branches.sh"
source "${ROOT_DIR}/management/utils.sh"

function __test () {
    echo "Hello, this is '$(basename "$0")' from '$(pwd)'"
}

function update_mutiny_module () {
    module="$1"
    # Boostrap submodule 
    if [ -e "${module}/${BOOTSTRAP_SUBMODULE}" ]
    then
        pushd "${module}" &> /dev/null
        "./${BOOTSTRAP_SUBMODULE}"
        popd &> /dev/null
    fi
}

#
# main
#
function main() {
    __test
    for module in "${MUTINY_MODULES[@]}"
    do
        update_mutiny_module "${module}"
    done
}

main "$@"
