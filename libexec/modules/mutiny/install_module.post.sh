#!/bin/bash
#
# modules/mutiny/install_module.post.sh module_name module_dir
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

    # INSTALL THE SQL STUFF
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -i                           || die "db.sh died ($!)" 
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r ps "${LIBDATA}/${SQL_PSDB}.init.sql" || die "db.sh died ($!)" 
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r wp "${LIBDATA}/${SQL_WPDB}.init.sql" || die "db.sh died ($!)"

    # RESTART APACHE
    $APACHECTL graceful
}

${DO} main "$@"
