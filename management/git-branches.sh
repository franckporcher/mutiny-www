#!/bin/bash
#
# git-branches - Specifications of existing modules, their 
#                repository name, and latest branches to fetch for update.
#
# PROJECT: MUTINY Tahiti's websites
#
# Copyright (C) 1995-2015 - Franck Porcher, Ph.D 
# www.franckys.com
# Tous droits réservés
# All rights reserved

declare -A RELEASE

#------[moduleName]--ReposName:BranchName---
RELEASE[mutiny-www]='mutiny-www:stable-v1.0'
RELEASE[cgm]='mutiny-www-cgm:stable-v1.0'
RELEASE[store]='mutiny-www-ps:init-1.6.0.14-v1.0'
RELEASE[wordpress]='mutiny-www-wp:init-4.1.1-v1.0'
