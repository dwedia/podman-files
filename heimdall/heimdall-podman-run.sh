#!/bin/bash

# create the directory
mkdir -p /opt/podmnts/heimdall/config

podman run -d --name heimdall -e PUID=1000 -e PGID=1000 -e TZ=Europe/Copenhagen -p 80:80 -p 443:443 -v /opt/podmnts/heimdall/config:/config:Z lscr.io/linuxserver/heimdall:latest

if [[ -d /home/ramiraz/.config/systemd/user ]];
then
  podman generate systemd heimdall > /home/ramiraz/.config/systemd/user/heimdall-podman.service
  systemctl --user daemon reload
  echo "systemd unit file has been creted. enable it with this command: systemctl --user enable heimdall-podman.service
else
  echo 'Systemd user folder "/home/ramiraz/.config/systemd/user" does not exist. Please create it'
fi



