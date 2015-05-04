#!/bin/bash
#
# run_script script options arguments
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 2014-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

#----------------------------------------
# LOAD RUNNING CONTEXT
#----------------------------------------
cd "$(dirname "$0")"    # cd into libexeec
SCRIPTNAME="$(basename "$0")"
SCRIPTFQN="$(pwd)/$SCRIPTNAME"

[ -z "${UTILS}" ] && UTILS="$(pwd)/utils.sh"
if [ -e "${UTILS}" ]
then
    source "${UTILS}"
else
    msg="[ERROR::$SCRIPTFQN (~$(pwd))] Cannot locate mandatory dependancy: ${UTILS}. Aborting!"
    echo "$msg" 1>&2
    logger -s -t "$SCRIPTNAME" "$*"
    exit 1
fi

    else
        return 0
    fi
}

$DO _EXEC_SCRIPT "$@"
