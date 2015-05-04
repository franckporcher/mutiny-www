#!/bin/bash
#
# modules/wordpress/install_module.post.sh module_name module_dir
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
    local module_specs="$(get_module_specs "${module_name}")"
    set ${module_specs}
    local install_dir="$4"
    if [ "${install_dir}" != "${module_dir}" ]
    then
        pushd "${install_dir}"
        chown -h "${WWWUID}:${WWWGID}" wp-* xmlrpc.php index.php license.txt readme.html
        popd
    fi

    # RESTORE THE INITIAL DB
    $DO _RUN_SCRIPT "${LIBEXEC}/db.sh" -r wp "${LIBDATA}/${SQL_WPDB}.init.sql" || die "[install_module.post.sh] db.sh died ($!)" 
}

${DO} main "$@"

