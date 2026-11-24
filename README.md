# Ashling examples – Codespace build and remote debug

Build the Ashling example in a **GitHub Codespace** and debug it on a board connected to a
remote machine. The Codespace joins the remote network over the **SonicWall VPN (NetExtender)**
and connects to an **Ashling GDB server** running on the remote PC.

```
 GitHub Codespace (cloud)                       Remote network
 ┌──────────────────────────┐   SonicWall VPN   ┌──────────────────────────────┐
 │ VS Code + Ashling ext.   │ ═════════════════ │ Remote PC  <gdbserver-pc-ip>  │
 │ Ashling SDK (Linux)      │   nxcli (TLS)     │ Ashling GDB server :<port>    │
 │ gdb ── target remote ────┼──────────────────▶│      │ USB                    │
 └──────────────────────────┘                   │  Debug probe ── target board  │
                                                └──────────────────────────────┘
```

## What's in the repo

| Path | What it is |
|---|---|
| `riscv-picojpeg-cmake/` | picojpeg example (CMake), built with the Ashling **RISC-V** SDK |
| `.devcontainer/` | Codespace definition: installs the NetExtender VPN client, and `vpn.sh` to connect |
| `.vscode/tasks.json` | **Connect VPN** task, run automatically when the Codespace opens |

## Before you start

You need:
- Access to this repo on GitHub, with Codespaces enabled for your account.
- Your **SonicWall VPN** login: server (`<vpn-server-ip>:4433`), username, password and, optionally, domain.
- For debugging: a PC on the remote network with an Ashling debug probe and the target board attached (see step 6).

---

## Getting started

### 1. (Optional) Save your VPN login as Codespaces secrets
Skip this to type the server, username and password each time the VPN connects (the password isn't shown).
Any secret that is set is used instead of asking.

GitHub → profile picture → **Settings → Codespaces → Codespace user secrets → New secret**.
For each one set **Repository access** to this repo.

| Secret | Where to find the value |
|---|---|
| `VPN_SERVER` | Windows NetExtender → Edit Connection → **Server** (`<vpn-server-ip>:4433`) |
| `VPN_USER` | Windows NetExtender → **Username** |
| `VPN_PASS` | Your VPN password |
| `VPN_DOMAIN` | The domain you pick at login (the **domain**, not the connection name like "Ireland VPN") |

Secrets are read only when a Codespace starts: after adding or changing one, stop and reopen the Codespace.

### 2. Open a Codespace
Repo page → green **`<> Code`** button → **Codespaces** tab → **Create codespace on main**.
The first start takes a few minutes: it installs the NetExtender VPN client.
Next time, open your **existing** Codespace from the same tab (nothing is reinstalled).

### 3. Connect the VPN
When the Codespace opens, the **Connect VPN** task runs in its own terminal.
If VS Code asks whether to allow automatic tasks, choose **Allow**. Click into that terminal and:
- Without secrets: enter the server (`<vpn-server-ip>:4433`), username and password.
- First time: at the server certificate prompt type **`T`** (Trust). It's Ashling's self-signed certificate.
- If asked *"Please select a domain(id)"* type the **number** (e.g. `1`). A `VPN_DOMAIN` secret skips this.

Success looks like:
```
NetExtender has been connected.
IPv4 Routes : <remote subnets>
Connected!!!
snwl_ssltunnel   UNKNOWN   <vpn-client-ip>/32
```
To connect again later (or check the connection), run `bash .devcontainer/vpn.sh`.
If the VPN is already up, it only prints the VPN interface.

### 4. Install the Ashling extension and SDK (first time per Codespace)
1. In the **Extensions** view, search for **Ashling RiscFree** and click **Install** (it installs in the Codespace).
2. From the extension's **SDK Manager**, download the **Linux RISC-V** SDK.

### 5. Build the example
1. Open the **Ashling Project View**. The repo shows as one project, **examples**.
2. Under **SDK Selection**, choose the **RISC-V** SDK.
3. Click **Build Actions → Build** (or Rebuild / Clean). It builds `riscv-picojpeg-cmake`.
4. Output goes to `riscv-picojpeg-cmake/build/`, and the binary is listed under **Binaries**.

### 6. Prepare the remote GDB server PC
On the PC with the debug probe (Windows):
1. Start the Ashling GDB server with the debug probe attached.
2. Find the PC's IP: run `ipconfig` and use the **Ethernet adapter Ethernet → IPv4 Address**.
3. Find the port in the terminal where the GDB server is running: it prints the port it listens on.
   You need this IP and port in steps 7 and 8 (`<gdbserver-pc-ip>` and `<port>`).

### 7. Check the GDB server is reachable
In the Codespace terminal:
```bash
nc -zv <gdbserver-pc-ip> <port>
```

| Result | Meaning |
|---|---|
| `succeeded` | Ready to debug |
| `Connection refused` | VPN works, but nothing listens on that port: GDB server not running, wrong port, or bound to `127.0.0.1` |
| times out | Wrong IP, or Windows Firewall blocks the port |

### 8. Debug
In the Ashling extension, add a **remote GDB server** debug configuration: host `<gdbserver-pc-ip>`,
port `<port>`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| No Codespaces button on the repo page | It's inside the green **`<> Code`** button → **Codespaces** tab |
| Connect VPN task didn't start | Run `bash .devcontainer/vpn.sh` in a terminal, or allow automatic tasks when VS Code asks |
| `nxcli not found` | The VPN client didn't install: rebuild the Codespace (**Codespaces: Rebuild Container**) |
| VPN asks to select a domain | Type the number; if you set `VPN_DOMAIN`, it must be the domain, not the connection name |
| Build fails with compiler errors | **SDK Selection** isn't the RISC-V SDK (step 5.2) |
| `nc` → `Connection refused` | GDB server not running, or on a different port (step 6.1) |
| `git` "Filename too long" when cloning on Windows | `git config core.longpaths true` |

---

## For maintainers

- **Codespace definition** (`.devcontainer/devcontainer.json`):
  - `runArgs: --cap-add=NET_ADMIN --cap-add=NET_RAW --device=/dev/net/tun` lets the container create the VPN tunnel.
  - `postCreateCommand` installs `netcat` and NetExtender from this repo's `netextender` release, once when the
    Codespace is created.
  - Turns on automatic tasks (`task.allowAutomaticTasks`) so **Connect VPN** runs when the folder opens.
  - Changes here need **Codespaces: Rebuild Container** in existing Codespaces. A change to `vpn.sh` only needs `git pull`.
- **`vpn.sh`**: uses the secrets that are set and asks for the rest; starts the NetExtender service by hand
  (`/usr/local/netextender/NEService`, Codespaces has no systemd) and connects with
  `sudo nxcli <server> -u <user> -p <password> [-d <domain>]`. Use this direct form: `nxcli connect` takes a saved profile.
- **Updating NetExtender**: download **NetExtender Linux AMD 64-Bit** (`.deb`) from SonicWall, then on GitHub edit
  the **`netextender`** release and drop the `.deb` into the **Attach binaries** box (the description box rejects
  `.deb`). Keep only one `.deb` there.
