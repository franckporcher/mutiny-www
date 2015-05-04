#!/bin/bash
#
# modules/store/install_module.post.sh module_name module_dir
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

    # Transfer ownership to WWW
    $DO chown -R "${WWWUID}:${WWWGID}" "${module_dir}"

    # RESTORE THE INITIAL DB
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r ps "${LIBDATA}/${SQL_PSDB}.init.sql" || die "[install_module.post.sh] db.sh died ($!)" 
}

${DO} main "$@"

