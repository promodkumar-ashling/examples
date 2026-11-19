#!/bin/bash
# Connects this codespace to the Ashling SonicWall VPN using NetExtender 10.x (nxcli).
# Needs codespace secrets: VPN_SERVER, VPN_USER, VPN_PASS, VPN_DOMAIN.
set -e
# NetExtender installs to /usr/local/netextender and symlinks into /usr/sbin, which isn't on the vscode user's PATH
export PATH=/usr/local/netextender:/usr/sbin:$PATH

for v in VPN_SERVER VPN_USER VPN_PASS VPN_DOMAIN; do
  [ -n "${!v}" ] || { echo "Missing codespace secret $v (GitHub > Settings > Codespaces). Restart the codespace after adding it."; exit 1; }
done

command -v nxcli >/dev/null || { echo "nxcli not found: NetExtender .deb did not install. Check the 'netextender' release in this repo."; exit 1; }

# No systemd in codespaces, so start the NetExtender background service by hand.
if ! pgrep -f NEService >/dev/null; then
  sudo /usr/local/netextender/NEService >/tmp/neservice.log 2>&1 &
  sleep 3
fi

# Direct form: nxcli <server[:port]> -u -p -d (no saved profile needed).
# First run may ask to trust the server certificate; answer it once. Not using --always-trust on purpose.
sudo nxcli "$VPN_SERVER" -u "$VPN_USER" -p "$VPN_PASS" -d "$VPN_DOMAIN"

sleep 5
echo "--- VPN interface ---"
ip -brief addr | grep -iE 'tun|ppp|sslvpn' || echo "No VPN interface yet; see /tmp/neservice.log"
echo "Test the gdbserver with: nc -zv <gdbserver-ip> <port>"
