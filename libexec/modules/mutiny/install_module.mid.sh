#!/bin/bash
#
# modules/mutiny/install_module.mid.sh module_name module_dir
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
cd "$(dirname "$0")"
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"
source "$UTILS"

#----------------------------------------
# main
#----------------------------------------
function main() {
    # Install the submodules
    local module_name="$1"
    local module_dir="$2"

    # INIT THE MYSQL DB
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -i || die "[install_module.mid.sh] db.sh died ($!)" 
}

${DO} main "$@"
