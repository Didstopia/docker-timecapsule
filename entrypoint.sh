#!/bin/bash

set -e

mkdir -p /conf.d/netatalk

## TODO: Only enable guest rw and default TM volume with an env var!
if [ ! -e /.initialized_afp ]; then
    rm /etc/afp.conf

    echo "[Global]
    mimic model = TimeCapsule8,119
    log file = /var/log/afpd.log
    log level = default:warn
    spotlight = yes
    #uam list = uams_guest.so
    #guest account = guest
    ea = ad
    zeroconf = yes" >> /etc/afp.conf

#    echo "
#[Time Machine]
#    path = /timemachine/shared
#    time machine = yes
#    spotlight = no
#    rwlist = nobody
#    " >> /etc/afp.conf

#    mkdir -p /timemachine/shared

    touch /.initialized_afp
fi

## TODO: If we really want to be able to add users, those also need to be able to persist, right?
##       Maybe when adding a user (in the binary itself), take a copy afp.conf and copy it to a volume,
##       then when starting back up, check if that file exists, and if so, use it instead?
if [ ! -e /.initialized_user ] && [ ! -z $AFP_LOGIN ] && [ ! -z $AFP_PASSWORD ]; then
    add-account $AFP_LOGIN $AFP_PASSWORD /timemachine/$AFP_LOGIN $AFP_SIZE_LIMIT
    ## TODO: This isn't a good fix, but I personally need a second account, so it'll have to do
    if [ ! -z $AFP_LOGIN2 ] && [ ! -z $AFP_PASSWORD2 ]; then
        add-account $AFP_LOGIN2 $AFP_PASSWORD2 /timemachine/$AFP_LOGIN2 $AFP_SIZE_LIMIT
    fi
    touch /.initialized_user
fi

## TODO: Double check that this needs to be the container's MAC address and not the host's
## TODO: Also what happens if the MAC changes, since I believe it does whenever recreated?
# Before starting, always make sure the MAC address is up to date
MAC_ADDRESS=`cat /sys/class/net/eth0/address`
sed -E -i "s/[0-9a-fA-F:]{17}/${MAC_ADDRESS}/" /etc/avahi/services/afpd.service

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
