#!/bin/bash

### Getting Permissions

rm -rf /haskell/*
mkdir -p /haskell

# Copy files for user to get permissions
cp -R /workspace/ /haskell

### VNC

# Set up VNC password
mkdir -p ~/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Start VNC server in the background, bound to localhost
vncserver -localhost yes &


### SSH Server

# BIG: ASSUMES YOU OVERLAY THE $USER'S .ssh folder into the container. WILL NOT WORK IF YOU DON'T

# 1. add machines preexisting key to its own authorized, no-password access list
# Why: If I overlay my .ssh/, the container inherits the user's no-password access list, tricking sshd to not need password
# How: This only needs to be run once, but want idempotency so do if-else check
grep -qxFf ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys || cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# 2. Dynamically generate sshd keys for the ssh server
mkdir -p ~/hostkeys
ssh-keygen -q -N "" -t rsa -b 4096 -f ~/hostkeys/ssh_host_rsa_key <<< y
exec /usr/sbin/sshd -D -p 2222 -o UsePAM=no -h ~/hostkeys/ssh_host_rsa_key