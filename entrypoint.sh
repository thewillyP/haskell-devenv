#!/bin/bash
set -euo pipefail

# Clear tmp files before anything else
rm -rf /tmp/* /tmp/.[!.]* /tmp/..?* 2>/dev/null || true

### VNC

# Retrieve VNC password from AWS SSM Parameter Store (secure string)
VNC_PASSWORD=$(aws ssm get-parameter \
  --name "/dev/general/vnc_password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

# Set up VNC password
mkdir -p ~/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Start VNC server in the background, bound to localhost
vncserver -localhost yes &

### SSH Server

# Fakeroot fixes (silent fail if not in fakeroot)
# 1. Remap sshd user to uid 0 (fixes privsep security check)
sed -i 's/^sshd:x:100:65534:/sshd:x:0:0:/' /etc/passwd 2>/dev/null || true
# 2. Tar wrapper to skip chown (fixes tar for VS Code server and any other tarballs)
(
cat > /usr/local/bin/tar << 'EOF'
#!/bin/bash
exec /bin/tar --no-same-owner "$@"
EOF
chmod +x /usr/local/bin/tar
) 2>/dev/null || true

# Dynamically generate sshd keys for the ssh server
mkdir -p ~/hostkeys
[ -f ~/hostkeys/ssh_host_rsa_key ] || ssh-keygen -q -N "" -t rsa -b 4096 -f ~/hostkeys/ssh_host_rsa_key

exec /usr/sbin/sshd -D -p 2002 \
    -o PermitUserEnvironment=yes \
    -o PermitTTY=yes \
    -o X11Forwarding=yes \
    -o AllowTcpForwarding=yes \
    -o GatewayPorts=yes \
    -o ForceCommand=/bin/bash \
    -o UsePAM=no \
    -h ~/hostkeys/ssh_host_rsa_key