#!/bin/bash

# Script to build the vpn stack pod and containers

# Ports used in this pod
# - 8080:8080 # SabNZBd port
# - 8112:8112 # Deluge port
# - 6881:6881 # Deluge port
# - 6881:6881/udp # Deluge port
# - 9696:9696 # Prowlarr port
# - 8989:8989 # Sonarr port
# - 7878:7878 # Radarr port

if [[ -d /opt/podmnts && -d /opt/netmounts ]];
then
  # Create a pod called vpn-stack
  # Options:
  # --name vpnStack  ### Sets the name of the pod
  # --share net ### tells the pod that containers inside should share network namespace
  # -p 8112:8112 -p 6881:6881 -p 6881:6881/udp ### exposes the ports needed by containers in the pod
  
  podman pod create --name vpnStack --share net -p 8112:8112 -p 6881:6881 -p 6881:6881/udp -p 8080:8080 -p 9696:9696 -p 8989:8989 -p 7878:7878
  
  ## Commands to manage the pod ##
  # podman pod start vpnStack ### Start the pod
  # podman pod stop vpnStack ### stops the pod
  # podman pod rm vpnStack ### removes the pod
  

  # create folder for gluetun config
  mkdir -p /opt/podmnts/gluetun/config

  # create gluetun container, and put it in the pod
  # Options:
  # -d ### detached - Run container in background and print container ID
  # --name gluetun ### Sets the name of the container (so it does not get assigned a randon name)
  # --pod vpnStack ### launches the container inside the pod vpnStack
  # --restart unless-stopped ### Sets restart policy
  # --privileged ### Give extended privileges to container
  # --cap-add NET_ADMIN ### adds NET_ADMIN capabilities to the container.
  # --device /dev/net/tun:/dev/net/tun ### passes /dev/net/tun in to the container
  # -v /opt/podmnts/gluetun/config:/gluetun:Z ### maps the config path in to the container, and sets SELinux context
  # -e VPN_SERVICE_PROVIDER=nordvpn ### Sets environment variable inside the container
  # -e SERVER_CONTRIES=Switzerland ### Sets environment variable inside the container
  # --env-file secrets.txt ### Read in a file of environment variables
  # --dns 1.1.1.1 ### Set custom DNS servers
  # qmcgaw/gluetun:latest ### the image used to create the container
  

  podman run -d --name gluetun --pod vpnStack --restart unless-stopped --privileged --cap-add NET_ADMIN --device /dev/net/tun:/dev/net/tun \
   -v /opt/podmnts/gluetun/config:/gluetun:Z \
   -e VPN_SERVICE_PROVIDER=nordvpn \
   -e SERVER_CONTRIES=Switzerland \
   --env-file secrets.txt \
   --dns 1.1.1.1 \
   qmcgaw/gluetun:latest
  

  # create folder for deluge config
  mkdir -p /opt/podmnts/deluge/config

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
  # -v /opt/podmnts/deluge/config:/config:Z ### maps the config path in to the container, and sets SELinux context
  # -v /opt/netmounts/new/Torrents/Complete/:/downloads:z ### maps the downloads path in to the container, and sets SELinux context
  # -v /opt/netmounts/new/Torrents/Incomplete/:/Incomplete:z ### maps the incomplete path in to the container, and sets SELinux context
  # --requires gluetun ### tells podman that this container cannot run unless gluetun container is running
  # --network container:gluetun ### Sends this containers network trafic through the gluetun container
  # linuxserver/deluge:latest ### the image used to create the container

  podman run -d --name deluge --pod vpnStack --restart unless-stopped \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=Europe/Copenhagen \
   -e DELUGE_LOGLEVEL=error \
   -v /opt/podmnts/deluge/config:/config:Z \
   -v /opt/netmounts/new/Torrents/Complete/:/downloads \
   -v /opt/netmounts/new/Torrents/Incomplete/:/Incomplete \
   --requires gluetun \
   --network container:gluetun \
   linuxserver/deluge:latest
  

  # create folder for sabnzbd config
  mkdir -p /opt/podmnts/sabnzbd/config

  # Create SabNZBd container
  podman run -d --name sabnzbd --pod vpnStack --restart unless-stopped \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=Europe/Copenhagen \
   -v /opt/podmnts/sabnzbd/config:/config:Z \
   -v /opt/netmounts/new/Complete:/downloads \
   -v /opt/netmounts/new/Incomplete:/incomplete-downloads \
   --requires gluetun \
   --network container:gluetun \
   lscr.io/linuxserver/sabnzbd:latest
  

  # create folder for prowlarr config
  mkdir -p /opt/podmnts/prowlarr/config

  # Create Prowlarr container
  podman run -d --name prowlarr --pod vpnStack --restart unless-stopped \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=Europe/Copenhagen \
   -v /opt/podmnts/prowlarr/config:/config:Z \
   --requires gluetun \
   --network container:gluetun \
   lscr.io/linuxserver/prowlarr:latest
  
  # create folder for sonarr config
  mkdir -p /opt/podmnts/sonarr/config

  # Create Sonarr container
  podman run -d --name sonarr --pod vpnStack --restart unless-stopped \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=Europe/Copenhagen \
   -v /opt/podmnts/sonarr/config:/config:Z \
   -v /opt/netmounts/tv:/tv \
   --requires gluetun \
   --network container:gluetun \
   lscr.io/linuxserver/sonarr:latest
  
  # create folder for radarr config
  mkdir -p /opt/podmnts/radarr/config

  # Create Radarr container
  podman run -d --name radarr --pod vpnStack --restart unless-stopped \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=Europe/Copenhagen \
   -v /opt/podmnts/radarr/config:/config:Z \
   -v /opt/netmounts/movies:/movies \
   --requires gluetun \
   --network container:gluetun \
   lscr.io/linuxserver/radarr:latest
  
else
  echo "Requires folders are not present"
  if [[ ! -d /opt/podmnts ]];
  then
    echo "Please create /opt/podmnts"
  fi
  if [[ ! -d /opt/netmounts ]];
  then
    echo "Please create /opt/netmounts"
  fi
fi




