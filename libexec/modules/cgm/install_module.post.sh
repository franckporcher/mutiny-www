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
    local envd="${module_dir}/env"

    # GENERAL ENV FOR PERL MODULES
    # ----------------------------
    # module_dir/
    #           env/
    #               plenv/
	#				dot.bashrc
    #
	if ! cd "${module_dir}"
	then
		echo "[$SCRIPTNAME] Cannot cd:[$module_dir]" 1>&2
		exit 1
	fi

	#
	# Env for plenv, carton, capnm, perl versions, etc.
	#
    [ ! -d "${envd}"  ] && mkdir -p "${envd}"


    # I. PLENV 
    # /!\ => we are in module_dir
    # --------
    ${DO} ${GIT} clone git://github.com/tokuhirom/plenv.git "${envd}/plenv"
    echo 'PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"; export PATH'    > "${envd}/dot.bashrc"
    echo "PATH=\"${envd}/plenv/bin:\$PATH\";            "   >> "${envd}/dot.bashrc"
    echo "PLENV_ROOT=\"${envd}/plenv\"; export PLENV_ROOT" >> "${envd}/dot.bashrc"

    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
    PATH="${envd}/plenv/bin:$PATH"
    PLENV_ROOT="${envd}/plenv";
    export PATH PLENV_ROOT

    echo 'eval "$(plenv init -)"' >> "${envd}/dot.bashrc"
    eval "$(plenv init -)"
    
    # 2. INSTALLING PERL-BUILD
    ${DO} ${GIT} clone git://github.com/tokuhirom/Perl-Build.git "${envd}/plugins/perl-build/"
    ${DO} plenv rehash

    # 3. INSTALLING Perl 5.20.1
    ${DO} plenv install 5.20.1
    ${DO} plenv rehash # Rebuild the shim executables
    
    # Set the global Perl version
    ${DO} plenv global 5.20.1
    
    # 4. INSTALLING CPANMINUS INTO THE CURRENT GLOBAL PERL
	${DO} plenv install-cpanm
    
    # 5. INSTALLING LOCAL::LIB for ~/perl5
	${DO} cpanm --local-lib="${module_dir}/local" local::lib
	local perlstuff="$( ${DO} perl -I local/lib/perl5/ -Mlocal::lib=local )"
    eval  "${perlstuff}"
    echo "${perlstuff}" >> "${envd}/dot.bashrc"
    
    # 6. INSTALLING CARTON
    ${DO} cpanm Carton
    
    # 7. DISTRO DEPLOYMENT (in module dir)
    ${DO} cd "${module_dir}"
    ${DO} ${TAR} xzf carton.deploy.tgz 
    # Check get cpanfile and cpanfile.snapshot
    ${DO} carton install --cached --deployment --path=./local 2>&1  | tee carton.deploy.log
    
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

    #install_perl_environment
    pushd .
    if cd "${module_dir}"
    then
        ${DO} install_perl_environment "${module_name}" "${module_dir}"
        $APACHECTL graceful
    else
        logtrace "[$SCRIPTNAME] Cannot cd:[module_dir]"
        return 1
    fi

}

${DO} main "$@"
