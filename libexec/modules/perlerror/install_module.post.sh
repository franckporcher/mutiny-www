#!/bin/bash
#
# modules/perltrace/install_module.post.sh module_name module_dir
#
# PROJECT: MUTINY Tahiti's websites
#
# perl5-Franckys-Error postinstall
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

PMFILE='Error.pm'

#----------------------------------------
# main
#----------------------------------------
function main() {
    local module_name="$1"
    local module_dir="$2"

    #--------------------
    # Parentmodule Specs
    #--------------------
    local parentmodule_name="$(get_parentmodule "${module_name}")"
    local parentmodule_specs="$(get_module_specs "${parentmodule_name}")"
    set ${parentmodule_specs}
    local parent_dir="$3"

    #--------------------
    # Symbolic link <CGM>/Parentmodule Specs
    #--------------------
    local src="${module_dir}/lib/Franckys/${PMFILE}"
    local dest="${parent_dir}/Franckys/${PMFILE}"
    [ -e "$dest" ] && $DO rm "$dest"
    $DO ln -s -f "${src}" "${dest}"
}

${DO} main "$@"
