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

    # RESTART APACHE
    $APACHECTL -k graceful

    # Give Apache ownership over its configuration files
    if [ -e  "${VHOST_CUSTOMLOG_1}" -o -e  "${VHOST_CUSTOMLOG_2}" -o -e "${VHOST_ERRORLOG}" ]
    then
        [ -e  "${VHOST_CUSTOMLOG_1}" ] && chown "${WWWUID}:${WWWGID}" "${VHOST_CUSTOMLOG_1}"
        [ -e  "${VHOST_CUSTOMLOG_2}" ] && chown "${WWWUID}:${WWWGID}" "${VHOST_CUSTOMLOG_2}"
        [ -e  "${VHOST_ERRORLOG}" ]    && chown "${WWWUID}:${WWWGID}" "${VHOST_ERRORLOG}"
        $APACHECTL -k graceful
    fi
}

${DO} main "$@"

