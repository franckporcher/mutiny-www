#!/bin/bash
#
# modules/cgm/install_module.pre.sh module_name module_dir
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
function install_perl_environment () {
    local module_name="$1"
    local module_dir="$2"

    # I. PLENV
    # --------
    # This will get you going with the latest version of plenv and make it easy to
    # fork and contribute any changes back upstream.
    ${DO} cd ${WWWHOME}

    # 1. INSTALLING PLENV
    ${DO} ${GIT} git://github.com/tokuhirom/plenv.git "${WWWHOME}/.plenv"
    echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> "${WWWHOME}/.bashrc"
    echo 'eval "$(plenv init -)"' >> "${WWWHOME}/.bashrc"
    PATH="${WWWHOME}/.plenv/bin:$PATH"
    eval "$(plenv init -)"
    
    # 2. INSTALLING PERL-BUILD
    ${DO} ${GIT} clone git://github.com/tokuhirom/Perl-Build.git "${WWWHOME}/.plenv/plugins/perl-build/"
    ${DO} plenv rehash
    
    # 3. INSTALLING Perl 5.20.1
    ${DO} plenv install 5.20.1
    
    # Rebuild the shim executables
    ${DO} plenv rehash
    
    # Set the global Perl version
    ${DO} plenv global 5.20.1
    
    # 4. INSTALLING CPANMINUS INTO THE CIRRENT GLOBAL PERL
    ${DO} plenv install-cpanm
    
    # 5. INSTALLING LOCAL::LIB for ~/perl
    PATH="${WWWHOME}/perl5/bin:$PATH" cpanm --local-lib=~/perl5 local::lib
    _perl_stuff="$(perl -I ${WWWHOME}/perl5/lib/perl5/ -Mlocal::lib=_zozo_ | sed s/_zozo_/perl5/)"
    eval "${_perl_stuff}"
    echo "${_perl_stuff}" >> "${WWWHOME}/.bashrc"
    [ -d '_zozo_' ] && ${DO} rm -rf _zozo_
    
    # 6. INSTALLING CARTON
    ${DO} cpanm Carton
    #echo 'PERL_CARTON_PATH=local; export PERL_CARTON_PATH' >> ~/.bashrc
    #export PERL_CARTON_PATH=local
    
    # 7. DISTRO DEPLOYMENT (in module dir)
    ${DO} cd "${module_dir}"
    ${DO} ${TAR} xzf carton.deploy.tgz 
    # Check get cpanfile and cpanfile.snapshot
    carton install --cached --deployment 2>&1  | tee carton.deploy.log
    
    # carton list
    # which perl
    # perl -V
    # sudo -E -S -g _www -u _www env
}



#----------------------------------------
# main
#----------------------------------------
function main() {
    # Install the submodules
    local module_name="$1"
    local module_dir="$2"
}

${DO} main "$@"

