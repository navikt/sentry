echo 'deb http://pkg.scaleft.com/deb linux main' | sudo tee -a /etc/apt/sources.list
curl -C - https://dist.scaleft.com/pki/scaleft_deb_key.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install scaleft-server-tools

sudo mkdir -p /etc/sft/

echo "AutoEnroll: true
CanonicalName: ${canonical_name}" | sudo tee /etc/sft/sftd.yaml

echo ${enrollment_token} | sudo tee /var/lib/sftd/enrollment.token

sudo systemctl restart sftd

echo "ForceCommand /sbin/nologin PermitTTY no
PasswordAuthentication no
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts no
X11Forwarding no
ClientAliveInterval 120
UseDNS no
TrustedUserCAKeys /var/lib/sftd/ssh_ca.pub" | sudo tee /etc/ssh/sshd_config

sudo systemctl restart sshd
echo 10.55.0.2 sentry.navtunnel >> /etc/hosts
