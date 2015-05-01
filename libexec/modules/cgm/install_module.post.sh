#!/bin/bash
#
# modules/cgm/install_module.post.sh module_name module_dir
#
# PROJECT: MUTINY Tahiti's websites
#
# Installing the global Perl environment necessary for all cgm
# related activities, scripts and web frontal applications.
#
# Copyright (C) 2015 - Franck Porcher, Ph.D 
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
# Perl & Bash environment
#----------------------------------------


#----------------------------------------
# main
#----------------------------------------
function main() {
    # Install the submodules
    local module_name="$1"
    local module_dir="$2"

    $APACHECTL graceful
}

${DO} main "$@"

