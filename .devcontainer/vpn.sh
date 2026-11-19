#!/bin/bash
# Connects this codespace to the Ashling SonicWall VPN using NetExtender 10.x (nxcli).
# Needs codespace secrets: VPN_SERVER, VPN_USER, VPN_PASS, VPN_DOMAIN.
set -e

for v in VPN_SERVER VPN_USER VPN_PASS VPN_DOMAIN; do
  [ -n "${!v}" ] || { echo "Missing codespace secret $v (GitHub > Settings > Codespaces). Restart the codespace after adding it."; exit 1; }
done

command -v nxcli >/dev/null || { echo "nxcli not found: NetExtender .deb did not install. Check the 'netextender' release in this repo."; exit 1; }

# No systemd in codespaces, so start the NetExtender background service by hand.
# ponytail: service binary located by search; hardcode the path once known.
if ! pgrep -f NEService >/dev/null; then
  SVC=$(command -v NEService || find /usr /opt -iname 'NEService' -type f 2>/dev/null | head -1)
  [ -n "$SVC" ] || { echo "NEService not found. Run: dpkg -L \$(dpkg -l | awk '/netextender/{print \$2}') and send the output."; exit 1; }
  sudo "$SVC" >/tmp/neservice.log 2>&1 &
  sleep 3
fi

# ponytail: flag names not verified on Linux 10.x; if this fails, check `nxcli connect --help`
nxcli connect -s "$VPN_SERVER" -u "$VPN_USER" -p "$VPN_PASS" -d "$VPN_DOMAIN"

sleep 5
echo "--- VPN interface ---"
ip -brief addr | grep -iE 'tun|ppp|sslvpn' || echo "No VPN interface yet; see /tmp/neservice.log"
echo "Test the gdbserver with: nc -zv <gdbserver-ip> <port>"
