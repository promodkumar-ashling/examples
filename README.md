# Ashling examples – Codespace build and remote debug

Build the Ashling examples in a **GitHub Codespace** and debug them on a real board connected to a
remote machine. The Codespace joins the remote network over the **SonicWall VPN (NetExtender)**
and connects to an **Ashling GDB server** running on the remote PC that has the **Opella-XD** probe attached.

```
 GitHub Codespace (cloud)                       Remote network
 ┌──────────────────────────┐   SonicWall VPN   ┌──────────────────────────────┐
 │ VS Code + Ashling ext.   │ ═════════════════ │ Remote PC  <gdbserver-pc-ip>  │
 │ Ashling SDK (Linux)      │   nxcli (TLS)     │ Ashling GDB server :<port>    │
 │ gdb ── target remote ────┼──────────────────▶│      │ USB                    │
 └──────────────────────────┘                   │  Opella-XD ── target board    │
                                                └──────────────────────────────┘
```

> **Security:** this repo is public. Never commit VPN addresses, usernames, passwords or remote machine IPs.
> They live only in Codespaces secrets (step 3). Values below in `<angle brackets>` are placeholders.

## Repository contents

| Path | What it is |
|---|---|
| `sum/` | Sum example from the Ashling examples package (`sum.zip`) |
| `riscv-picojpeg-cmake/` | picojpeg example |
| `.devcontainer/devcontainer.json` | Codespace definition: Ubuntu, GitHub CLI, tun device, installs NetExtender |
| `.devcontainer/vpn.sh` | Connects the Codespace to the remote network VPN |
| `.gitattributes` | Keeps `*.sh` files with LF line endings so they run on Linux |
| `examples.code-workspace` | Opens each example as its own folder so they build separately |
| `.gitignore` | Keeps generated `build/` and `.vscode/` out of git |

---

## One-time setup

### 1. Put the examples in the repo
1. Took `sum.zip` from the Ashling examples vcpkg artifact and unzipped it.
2. Created this repo on GitHub (empty: no README / .gitignore / license) and pushed the example.

### 2. Upload the Linux VPN client as a release
1. From the SonicWall download page, picked **NetExtender Linux AMD 64-Bit**
   (file `NetExtender-linux-amd64-10.3.6-39.deb`, Ubuntu x64 package).
2. On GitHub: **Releases → Create a new release**, tag **`netextender`**, title `netextender`.
3. Dropped the `.deb` into the **"Attach binaries by dropping them here"** box near the bottom
   (the description box rejects `.deb` with "We don't support that file type"), then **Publish release**.

### 3. Store the VPN login as Codespaces secrets
GitHub → profile picture → **Settings → Codespaces → Codespace user secrets → New secret**.
For each one set **Repository access** to this repo.

| Secret | Where to find the value |
|---|---|
| `VPN_SERVER` | Windows NetExtender → Edit Connection → **Server** (`<vpn-server-ip>:4433`) |
| `VPN_USER` | Windows NetExtender → **Username** |
| `VPN_PASS` | Your VPN password |
| `VPN_DOMAIN` | The domain name you pick at login (the **domain**, not the connection name like "Ireland VPN") |

Secrets are read only when a Codespace starts: after adding or changing one, stop and reopen the Codespace.

### 4. Codespace setup files (already in this repo)
- **`devcontainer.json`**
  - `runArgs: --cap-add=NET_ADMIN --cap-add=NET_RAW --device=/dev/net/tun` – lets the container create the VPN tunnel.
  - `postCreateCommand` – installs `netcat` and downloads + installs NetExtender from the `netextender` release.
    Runs **once when the Codespace is created**, not on every start.
- **`vpn.sh`**
  - Checks the 4 secrets exist.
  - Starts the NetExtender service by hand (`/usr/local/netextender/NEService`) – Codespaces has no systemd.
  - Connects with `sudo nxcli "$VPN_SERVER" -u "$VPN_USER" -p "$VPN_PASS" -d "$VPN_DOMAIN"`.

### 5. Prepare the remote GDB server PC
1. Find the PC's real IP: run `ipconfig` and use the **Ethernet adapter Ethernet → IPv4 Address**.
   Ignore `VMware Network Adapter VMnet1/VMnet8` addresses (e.g. `192.168.x.1`) – they are not reachable from outside the PC.
2. The IP must be inside a range the VPN routes (shown as **IPv4 Routes** when `vpn.sh` connects).
   If it isn't, ask IT to add that subnet to the SonicWall routes.
3. Start the Ashling GDB server with the Opella-XD attached. It must:
   - listen on all interfaces (`0.0.0.0:<port>`), not `127.0.0.1` – check with
     `netstat -ano | findstr LISTENING`
   - be allowed by Windows Firewall (Administrator Command Prompt):
     ```
     netsh advfirewall firewall add rule name="Ashling gdbserver" dir=in action=allow protocol=TCP localport=<port>
     ```
4. The **probe is selected on the GDB server side** (serial number on its command line). The Ashling extension's
   probe dropdown stays empty in a Codespace – there is no USB there, and that's expected.

---

## Every time

### 6. Open the Codespace
Repo page → green **`<> Code`** button → **Codespaces** tab →
**Create codespace on main** (first time) or click your **existing** Codespace (nothing reinstalls).

Rebuild (**Codespaces: Rebuild Container**) is only needed when `devcontainer.json` changes.
A change to `vpn.sh` only needs `git pull`.

### 7. Install the Ashling extension and SDK (first time per Codespace)
1. Install the Ashling RiscFree `.vsix` **inside the Codespace** (it must show under *Codespace – Installed*, not *Local*).
2. Let the extension download the **Linux** Ashling SDK.
3. Open the workspace: **☰ → File → Open Workspace from File… → `examples.code-workspace`**.
   Each example (`sum`, `picojpeg`) shows as its own folder; build the one you want.
   Opening the repo root instead makes the extension build only the first CMake project it finds.

### 8. Connect the VPN
```bash
bash .devcontainer/vpn.sh
```
- First run: certificate prompt → answer **`T`** (Trust). It's Ashling's self-signed server certificate.
- If asked *"Please select a domain(id)"* type the **number** (e.g. `1`), and fix the `VPN_DOMAIN` secret.
- Success looks like:
  ```
  NetExtender has been connected.
  IPv4 Routes : <remote subnets>
  Connected!!!
  snwl_ssltunnel   UNKNOWN   <vpn-client-ip>/32
  ```

### 9. Check the GDB server is reachable
```bash
nc -zv <gdbserver-pc-ip> <port>
```

| Result | Meaning |
|---|---|
| `succeeded` | Ready to debug |
| `Connection refused` | VPN works, but nothing listens on that port: GDB server not running, wrong port, or bound to `127.0.0.1` |
| times out | IP not in VPN routes, or Windows Firewall blocks the port |

### 10. Debug
In the Ashling extension create a **remote GDB server** debug configuration:
host `<gdbserver-pc-ip>`, port `<port>`, do **not** start a local GDB server. Press **F5**.

---

## Problems hit and fixes

| Problem | Fix |
|---|---|
| No Codespaces button on the repo page | It's inside the green **`<> Code`** button → **Codespaces** tab |
| Release upload: "We don't support that file type" | Use the **Attach binaries** box, not the description box |
| `git` "Filename too long" on Windows | `git config core.longpaths true` |
| `nxcli not found` | NetExtender links `nxcli` into `/usr/sbin` (not on the user's PATH); `vpn.sh` adds `/usr/local/netextender` to PATH |
| `nxcli connect`: `unknown shorthand flag: 's'` | `nxcli connect` takes a saved profile name; use the direct form `nxcli <server:port> -u -p -d` |
| VPN asks to select a domain | `VPN_DOMAIN` held the connection name; set it to the real domain |
| `nc` to `192.168.x.1` fails | That's a VMware adapter; use the Ethernet adapter IP |
| `nc` → `Connection refused` | See step 5.3 – GDB server port / bind address |

## Status / to do
- [x] Example hosted on GitHub
- [x] Codespace created, NetExtender installed, VPN connected from the Codespace
- [x] Remote PC reachable over VPN (`nc` gets *Connection refused*, i.e. the host answers)
- [ ] GDB server listening on a network port, `nc` → `succeeded`
- [ ] Full debug session (load, breakpoint, step) with F5
- [ ] Optional: make the repo Private; auto-connect VPN with `"postStartCommand": "bash .devcontainer/vpn.sh"`
