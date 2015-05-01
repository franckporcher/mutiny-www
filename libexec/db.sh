#!/bin/bash
#
# db.sh -- Scripted management of MUTINY Tahiti's MySQL databases
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 2014-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

#----------------------------------------
# BEGIN
#----------------------------------------
cd "$(dirname "$0")"
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


#----------------------------------------
# MYSQL DB CREDENTIALS (imported by utils.sh)
#----------------------------------------

#----------------------------------------
# HELP
#----------------------------------------
function help () {
	cat <<-EOT
        Usage: $SCRIPTNAME [OPTIONS] [CMD] [ARGS]

        OPTIONS:
            -h          Display this help

        CMD:
            -d DB FILE  Dump Mutiny's database DB to file FILE
            -r DB FILE  Restore Mutiny's database DB with file FILE
            -s DB       Reset Mutiny's database DB
            -i          Init/Reset everything

        ARGS:
            DB::
                ps      Mutiny's Prestashop database
                wp      Mutiny's WordPress database
            FILE::      Any sql file
                        Defaults to using 'psmutiny.sql' for ps database
                        and 'wpmutiny.sql' for wp database

		Copyright (C) 2015 - Franck Porcher, Ph.D. - All rights reserved
	EOT
}

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
OPTSTRING=":hd:r:s:i"
OP=
DB=

while getopts "$OPTSTRING" OPTION
do
    case "${OPTION}" in
        h) help && exit 0
           ;;
        d) OP=_mysql_dump_db
           DB="${OPTARG}"
           ;;
        r) OP=_mysql_restore_db
           DB="${OPTARG}"
           ;;
        s) OP=_mysql_reset_db
           DB="${OPTARG}"
           ;;
        i) OP=_mysql_init_all
           DB=ps
           ;;

      '?') die "Invalid option: ${OPTARG}"
           ;;

        :) die "Missing argument for option: ${OPTARG}"
           ;;
    esac
done

shift $((OPTIND - 1))


#----------------------------------------
# HELPERS
#----------------------------------------
# _mysql_dump_db DB SQLFILE
function _mysql_dump_db () {
    local DBNAME="$1"
    local SQLFILE="$2"
    [ -z "${SQLFILE}" ] && SQLFILE="${DBNAME}.sql"
    ${DO} mysqldump "--host=${SQL_DBSERVER}" -u "${SQL_DBADMIN}" "--password=${SQL_DBADMIN_PWD}" "${DBNAME}" > "${SQLFILE}"
}

function _mysql_restore_db () {
    local DBNAME="$1"
    local SQLFILE="$2"
    [ -z "${SQLFILE}" ] && SQLFILE="${DBNAME}.sql"
    if [ -e "${SQLFILE}" ]
    then 
        ${DO} mysql "--host=${SQL_DBSERVER}" -u "${SQL_DBADMIN}" "--password=${SQL_DBADMIN_PWD}" "${DBNAME}" < "${SQLFILE}"
    else
        die "Cannot locate sql-file: ${SQLFILE}"
    fi
}

function _mysql_reset_db () {
    local DBNAME="$1"
    ${DO} mysql --force "--host=${SQL_DBSERVER}" -u "${SQL_ROOT}" -p <<-EOT
        DROP DATABASE ${DBNAME};
        CREATE DATABASE ${DBNAME} CHARSET utf8 COLLATE 'utf8_general_ci';
        GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${SQL_DBADMIN}';
EOT
}

function _mysql_init_all () {
    ${DO} mysql --force "--host=${SQL_DBSERVER}" -u "${SQL_ROOT}" -p <<-EOT
        GRANT ALL PRIVILEGES ON *.* TO '${SQL_ROOT}' WITH GRANT OPTION;

        DROP USER '${SQL_DBADMIN}';
        REVOKE ALL PRIVILEGES ON ${SQL_PSDB}.* FROM '${SQL_DBADMIN}';
        REVOKE ALL PRIVILEGES ON ${SQL_WPDB}.* FROM '${SQL_DBADMIN}';
        REVOKE ALL PRIVILEGES ON *.* FROM '${SQL_DBADMIN}';
        CREATE USER '${SQL_DBADMIN}' IDENTIFIED BY '${SQL_DBADMIN_PWD}';

        DROP DATABASE ${SQL_PSDB};
        CREATE DATABASE ${SQL_PSDB} CHARSET utf8 COLLATE 'utf8_general_ci';
        GRANT ALL PRIVILEGES ON ${SQL_PSDB}.* TO '${SQL_DBADMIN}';

        DROP DATABASE ${SQL_WPDB};
        CREATE DATABASE ${SQL_WPDB} CHARSET utf8 COLLATE 'utf8_general_ci';
        GRANT ALL PRIVILEGES ON ${SQL_WPDB}.* TO '${SQL_DBADMIN}';
EOT
}


#----------------------------------------
# MAIN
#----------------------------------------
function main () {
    [ -z "${OP}" ] && help && exit 0;

    local SQLFILE="$1"

    case "$DB" in
        ps) DB="${SQL_PSDB}"
            ;;
        wp) DB="${SQL_WPDB}"
            ;;
        *)
            die "Invalid Database reference: $DB (Please refer to --help, or -h)"
            ;;
    esac
            
    $DO "${OP}" "${DB}" "${SQLFILE}"
}

main "$@"
