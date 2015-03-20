#!/bin/bash
#
# db.sh -- Scripted management of MUTONY Tahiti's MySQL databases
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

#----------------------------------------
# HELP
#----------------------------------------
function help () {
	cat <<-EOT
        Usage: $(basename "$0") [OPTIONS] [CMD] [ARGS]

        OPTIONS:
            -h          Display this help

        CMD:
            -d ps       Dump Mutiny's Prestashop database
            -d wp       Dump Mutiny's WordPress database
            -r ps       Restore Mutiny's Prestashop database
            -r wp       Restore Mutiny's WordPress database
            -s ps       Reset Mutiny's Prestashop database
            -s wp       Reset Mutiny's WordPress database

        ARGS:
            ps         Mutiny's Prestashop database
            wp         Mutiny's WordPress database

            sql.file   input or output sql filename.
                       Defaults to using 'psmutiny.sql' for ps database
                       and 'wpmutiny.sql' for wp database

		Copyright (C) 2015 - Franck Porcher, Ph.D. - All rights reserved
	EOT
}


#----------------------------------------
# DEBUG
#----------------------------------------
function log () {
    logger -s -t "$(basename $0)" "$*"
}

function die () {
    echo "ERROR: $*. Exiting!" 1>&2
    log "ERROR: $*. Exiting!"
    exit 1
}

function do () {
	echo "DO: $*" 1>&2
	"$@"
}

function do_continue () {
    local choice

	echo "DO: $*" 1>&2
	"$@"

    echo -n "Continue: [N/y]> " 1>&2
    read choice

    if [ "$choice" == "y" ]
    then
        return 0
    else
        die "Abandon."
    fi
}

# Choose one.
#   echo :       trace but do nothing
#   do_continue: reports step by step operation, with the option to exit the script at each step
#   do         : reports step by step operation
#DO=do
#DO=do_continue
#DO=echo
DO=


#----------------------------------------
# OPTIONS
#----------------------------------------
# **REMINDER**
# - OPTION gets the character option
# - OPTARG gets the argument if the option takes one, indicated by a colon after
#   the option
# - OPTIND contains the index of the next argument to be processed into the
# shell
#
# -Error handling:
#   > bad option found:           '?' into OPTION and option into OPTARG
#   > option argument missing:    ':' into OPTION and option into OPTARG 
# 
OPTSTRING=":hd:r:s:"
OP=
DB=

while getopts "$OPTSTRING" OPTION
do
    case "${OPTION}" in
        h) help && exit 0
           ;;
        d) OP=dump
           DB="${OPTARG}"
           ;;
        r) OP=restore
           DB="${OPTARG}"
           ;;
        s) OP=reset
           DB="${OPTARG}"
           ;;

      '?') die "Invalid option: ${OPTARG}"
           ;;

        :) die "Missing argument for option: ${OPTARG}"
           ;;
    esac
done

shift $((OPTIND - 1))
echo "$@"


#----------------------------------------
# HELPERS
#----------------------------------------
SRC_HOST=localhost
DEST_HOST=sql.mutinytahiti.com

SRC_DB_ROOT=root
DEST_DB_ROOT=root
SRC_DB_ADMIN=mutiny_db_admin
DEST_DB_ADMIN=mutiny_db_admin

DB_PS=psmutiny
DB_WP=wpmutiny


function dump_ps () {
    file="$1"
    [ -z "${file}" ] && file="${DB_PS}.sql"
    ${DO} mysqldump --host="${SRC_HOST}" "${DB_PS}" -u "${SRC_DB_ADMIN}" -p > "${file}"
}

function dump_wp () {
    file="$1"
    [ -z "${file}" ] && file="${DB_WP}.sql"
    ${DO} mysqldump --host="${SRC_HOST}" "${DB_WP}" -u "${SRC_DB_ADMIN}" -p > "${file}"
}

function restore_ps () {
    file="$1"
    [ -z "${file}" ] && file="${DB_PS}.sql"
    ${DO} mysql --host="${DEST_HOST}" "${DB_PS}" -u "${DEST_DB_ADMIN}" -p < "${file}"
}

function restore_wp () {
    file="$1"
    [ -z "${file}" ] && file="${DB_PS}.sql"
    ${DO} mysql --host="${DEST_HOST}" "${DB_WP}" -u "${DEST_DB_ADMIN}" -p < "${file}"
}

function reset_ps () {
    ${DO} mysql --host="${DEST_HOST}" "${DB_PS}" -u "${DEST_DB_ROOT}" -p <<-EOT
        DROP DATABASE ${DB_PS};
        CREATE DATABASE ${DB_PS} CHARSET utf8 COLLATE 'utf8_general_ci';
        GRANT ALL PRIVILEGES ON ${DB_PS}.* TO '${SRC_DB_ADMIN}';
EOT
}

function reset_wp () {
    ${DO} mysql --host="${DEST_HOST}" "${DB_WP}" -u "${DEST_DB_ROOT}" -p <<-EOT
        DROP DATABASE ${DB_WP};
        CREATE DATABASE ${DB_WP} CHARSET utf8 COLLATE 'utf8_general_ci';
        GRANT ALL PRIVILEGES ON ${DB_WP}.* TO '${SRC_DB_ADMIN}';
EOT
}


#----------------------------------------
# MAIN
#----------------------------------------
function main () {
    [ -z "${OP}" ] && help && exit 0;

    case "$DB" in
        ps) :
            ;;
        wp) :
            ;;
        *)
            die "Invalid Database reference: $DB (Please refer to --help, or -h)"
            ;;
    esac
            
    "${OP}_${DB}" "${1}"
}

main "$@"
