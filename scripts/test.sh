#!/bin/bash
# -------------------------------------------------------
# TECHNOGIX
# -------------------------------------------------------
# Copyright (c) [2022] Technogix SARL
# All rights reserved
# -------------------------------------------------------
# Module to deploy an aws bucket with all the secure
# components required
# Bash script to tests in a container
# -------------------------------------------------------
# Nadège LEMPERIERE, @13 january 2022
# Latest revision: 11 march 2022
# -------------------------------------------------------

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Launch tests in docker container
docker run  -it --rm \
            --volume $scriptpath/../:/home/technogix/module:rw \
            --volume $scriptpath/../../vault/:/home/technogix/vault \
            --env VAULT_KEY=$VAULT_KEY \
            --workdir /home/technogix/module \
            technogix/terraform-python-awscli:v2.0.0 \
            ./scripts/robot.sh -k VAULT_KEY $@
