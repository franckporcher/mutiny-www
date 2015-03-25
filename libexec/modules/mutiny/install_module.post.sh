#!/bin/bash
#
# modules/mutiny/boostrap.post.sh module
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

    # INSTALL THE SQL STUFF
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -i                      || die "db.sh died ($!)" 
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r ps psmutiny.init.sql || die "db.sh died ($!)" 
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r wp wpmutiny.init.sql || die "db.sh died ($!)"
}

${DO} main "$@"
