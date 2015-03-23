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
    module_name="$1"

    # INSTALL THE SQL STUFF
    echo $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -i                      || die "db.sh died ($!)" 
    echo $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r ps psmutiny.init.sql || die "db.sh died ($!)" 
    echo $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r wp wpmutiny.init.sq  || die "db.sh died ($!)"
}

${DO} main "$@"
