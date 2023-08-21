#!/bin/bash

# Script to build the vpn stack pod and containers

# Create a pod called vpn-stack
# Options:
# --name vpnStack  ### Sets the name of the pod
# --share net ### tells the pod that containers inside should share network namespace
# -p 8112:8112 -p 6881:6881 -p 6881:6881/udp ### exposes the ports needed by containers in the pod

podman pod create --name vpnStack --share net -p 8112:8112 -p 6881:6881 -p 6881:6881/udp

# create gluetun container, and put it in the pod
# Options:
# -d ### detached - Run container in background and print container ID
# --name gluetun ### Sets the name of the container (so it does not get assigned a randon name)
# --pod vpnStack ### launches the container inside the pod vpnStack
# --restart unless-stopped ### Sets restart policy
# --privileged ### Give extended privileges to container
# --cap-add NET_ADMIN ### adds NET_ADMIN capabilities to the container.
# --device /dev/net/tun:/dev/net/tun ### passes /dev/net/tun in to the container
# -v /home/ramiraz/podmnts/gluetun/config:/gluetun:Z ### maps the config path in to the container, and sets SELinux context
# -e VPN_SERVICE_PROVIDER=nordvpn ### Sets environment variable inside the container
# -e SERVER_CONTRIES=Switzerland ### Sets environment variable inside the container
# --env-file secrets.txt ### Read in a file of environment variables
# --dns 1.1.1.1 ### Set custom DNS servers
# qmcgaw/gluetun:latest ### the image used to create the container

podman run -d --name gluetun --pod vpnStack --restart unless-stopped --privileged --cap-add NET_ADMIN --device /dev/net/tun:/dev/net/tun \
 -v /home/ramiraz/podmnts/gluetun/config:/gluetun:Z \
 -e VPN_SERVICE_PROVIDER=nordvpn \
 -e SERVER_CONTRIES=Switzerland \
 --env-file secrets.txt \
 --dns 1.1.1.1 \
 qmcgaw/gluetun:latest

# create deluge container, and put it in the pod
# Options:
# -d ### detached - Run container in background and print container ID
# --name gluetun ### Sets the name of the container (so it does not get assigned a randon name)
# --pod vpnStack ### launches the container inside the pod vpnStack
# --restart unless-stopped ### Sets restart policy
# -e PUID=1000 ### userid of user outside container (found with the id command)
# -e PGID=1000 ### groupid of user outside container (found with the id command)
# -e TZ=Europe/Copenhagen ### sets timezone inside container
# -e DELUGE_LOGLEVEL=error ### sets loglevel. can be raised or lowered as needed
# -v /home/ramiraz/podmnts/deluge/config:/config:Z ### maps the config path in to the container, and sets SELinux context
# -v /home/ramiraz/podmnts/media/new/Torrents/Complete/:/downloads:z ### maps the downloads path in to the container, and sets SELinux context
# -v /home/ramiraz/podmnts/media/new/Torrents/Incomplete/:/Incomplete:z ### maps the incomplete path in to the container, and sets SELinux context
# --requires gluetun ### tells podman that this container cannot run unless gluetun container is running
# linuxserver/deluge:latest ### the image used to create the container

podman run -d --name deluge --pod vpnStack --restart unless-stopped \
 -e PUID=1000 \
 -e PGID=1000 \
 -e TZ=Europe/Copenhagen \
 -e DELUGE_LOGLEVEL=error \
 -v /home/ramiraz/podmnts/deluge/config:/config:Z \
 -v /home/ramiraz/podmnts/media/new/Torrents/Complete/:/downloads:z \
 -v /home/ramiraz/podmnts/media/new/Torrents/Incomplete/:/Incomplete:z \
 --requires gluetun \
 linuxserver/deluge:latest


## Commands to manage the pod ##
# podman pod start vpnStack ### Start the pod
# podman pod stop vpnStack ### stops the pod
# podman pod rm vpnStack ### removes the pod


