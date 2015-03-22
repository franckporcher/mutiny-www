#!/bin/bash
#
# boostrap.post.sh
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

# cd to the root repository
#

#----------------------------------------
# BEGIN
#----------------------------------------
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"
cd "$(dirname "$0")"
source "./management/utils.sh"


#
# main
#
function main() {
    # Install the submodules
    top_module="${MODULES[root]}"
    $DO rec_bootstrap_module "${top_module}"

    # INSTALL THE SQL STUFF
    $DO ./management/db.sh -i
    $DO ./management/db.sh -r ps psmutiny.init.sql
    $DO ./management/db.sh -r wp wpmutiny.init.sql
}

main
