#!/bin/bash

# create a podman network for the vpnStack.
podman network create --driver bridge --subnet 192.168.100.0/24 --label io.podman.compose.project=gluetun gluetun

# check which networks are created.
podman network ls
