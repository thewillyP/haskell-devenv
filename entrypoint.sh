#!/bin/bash

# Retrieve VNC password from AWS SSM Parameter Store (secure string)
VNC_PASSWORD=$(aws ssm get-parameter \
  --name "/dev/general/vnc_password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

# Clear tmp files before anything else
rm -rf /tmp/* /tmp/.[!.]* /tmp/..?* 2>/dev/null || true

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
exec /usr/sbin/sshd -D -p 2222 \
  -o PermitUserEnvironment=yes \
  -o PermitTTY=yes \
  -o X11Forwarding=yes \
  -o AllowTcpForwarding=yes \
  -o GatewayPorts=yes \
  -o ForceCommand=/bin/bash \
  -o UsePAM=no \
  -h ~/hostkeys/ssh_host_rsa_key
