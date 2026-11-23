#!/bin/bash
# Connects this codespace to the Ashling SonicWall VPN using NetExtender 10.x (nxcli).
# Optional codespace secrets: VPN_SERVER, VPN_USER, VPN_PASS, VPN_DOMAIN. Missing ones are asked for.
set -e

# Already connected (e.g. auto-connected at start)? Nothing to do.
if ip -brief addr 2>/dev/null | grep -q snwl_ssltunnel; then
  echo "VPN already connected:"; ip -brief addr | grep snwl_ssltunnel; exit 0
fi
# NetExtender installs to /usr/local/netextender and symlinks into /usr/sbin, which isn't on the vscode user's PATH
export PATH=/usr/local/netextender:/usr/sbin:$PATH

# Each value comes from a codespace secret if set, otherwise it is asked for here.
[ -n "$VPN_SERVER" ] || read -rp "VPN server (host:port): " VPN_SERVER
[ -n "$VPN_USER" ]   || read -rp "VPN username: " VPN_USER
[ -n "$VPN_PASS" ]   || { read -rsp "VPN password: " VPN_PASS; echo; }
[ -n "$VPN_SERVER" ] && [ -n "$VPN_USER" ] && [ -n "$VPN_PASS" ] || { echo "Server, username and password are required."; exit 1; }
# Domain is optional: without it nxcli shows the domain list and asks for its number.
DOMAIN_ARGS=()
[ -n "$VPN_DOMAIN" ] && DOMAIN_ARGS=(-d "$VPN_DOMAIN")

command -v nxcli >/dev/null || { echo "nxcli not found: NetExtender .deb did not install. Check the 'netextender' release in this repo."; exit 1; }

# No systemd in codespaces, so start the NetExtender background service by hand.
if ! pgrep -f NEService >/dev/null; then
  # nohup: keep the service alive after the task's shell exits
  sudo nohup /usr/local/netextender/NEService >/tmp/neservice.log 2>&1 &
  sleep 3
fi

# Direct form: nxcli <server[:port]> -u -p -d (no saved profile needed).
# First run may ask to trust the server certificate; answer it once. Not using --always-trust on purpose.
sudo nxcli "$VPN_SERVER" -u "$VPN_USER" -p "$VPN_PASS" "${DOMAIN_ARGS[@]}"

sleep 5
echo "--- VPN interface ---"
ip -brief addr | grep -iE 'tun|ppp|sslvpn' || echo "No VPN interface yet; see /tmp/neservice.log"
echo "Test the gdbserver with: nc -zv <gdbserver-ip> <port>"
