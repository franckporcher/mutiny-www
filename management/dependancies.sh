#
# dependancies.sh -- Bash dependancies for local bash-based utilities
#
# File must be sourced (source xxx), and not ran !
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# All rights reserved
#

REALPATH="$(which realpath)"

##
# __bootstrap REALPATH realpath __realpath
function __bootstrap() {
    util_ref_name="$1"
    util_real_name="$2"
    util_bs_name="$3"

    _path="$(which "${util_real_name}")"
    [ -z "${_path}" ] && _path="${util_bs_name}"

    eval "${util_ref_name}='${_path}'"
}

##
# Bootstrap functions
#
__bootstrap REALPATH realpath __realpath


##
# Bootstrap code
#

# $resolved_path="$(__realpath $path)"
function __realpath () {
    echo "$1"
}
