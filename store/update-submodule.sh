#!/bin/bash
#
# update-submodule.sh -- Update MUTINY Tahiti's Prestashop-based store submodule
#                        from github specifications set
#                        in <siteroot>/management/git-branches.sh
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved


ROOT_DIR=..

# 
# cd to the root repository
#
cd "$(dirname "$0")"
source "${ROOT_DIR}/management/git-branches.sh"
source "${ROOT_DIR}/management/utils.sh"

function __test () {
    echo "Hello, this is '$(basename "$0")' from '$(pwd)'"
}

function install_submodule () {
    install_github_branch
}

#
# main
#
function main() {
    __test
    install_submodule
}

main
