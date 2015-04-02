#!/bin/bash

function hostname () {
    echo TEST
}
source utils.sh
DO=do_trace
export DO

install_config_files "$1"
