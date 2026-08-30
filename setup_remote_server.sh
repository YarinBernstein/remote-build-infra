#!/bin/bash
# Run this ONCE on a fresh Oracle Cloud Always Free VM (Oracle Linux 9) to
# prepare it as the remote Docker Buildx build server. SSH in as opc/root
# and run: bash setup_remote_server.sh
#
# Replaces the manual "remote server side" steps from TODO.md.

set -euo pipefail

echo "Installing and enabling Docker..."
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "Opening SSH (port 22) on the OS firewall..."
# Oracle Linux images ship with firewalld/iptables rules that block traffic
# even when the VCN Security List allows it - this trips people up constantly.
if command -v firewall-cmd > /dev/null 2>&1; then
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
fi

echo "Scheduling daily build cache cleanup at 03:00..."
( crontab -l 2>/dev/null | grep -v 'docker system prune' ; \
  echo '0 3 * * * docker system prune -a --volumes -f --filter "until=24h"' ) | crontab -

echo "Enabling SSH daemon..."
sudo systemctl enable --now sshd

echo "Generating a fresh SSH keypair for CI access..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo ""
echo "=== Setup complete ==="
echo "Log out and back in for the 'docker' group membership to take effect."
echo ""
echo "Put these two values in your CI secrets store (Vault) - do NOT commit them:"
echo ""
echo "--- REMOTE_SECRET_SSH_KEY (private, keep secret) ---"
cat ~/.ssh/id_ed25519
echo ""
echo "--- Host public key (safe to share - goes in known_hosts) ---"
cat /etc/ssh/ssh_host_ed25519_key.pub
