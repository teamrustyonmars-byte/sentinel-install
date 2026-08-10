# sentinel-install

**Scrubbed, installable profiles** for a small Linux homelab stack — **without** shipping real IPs, sudo passwords, or family data.

Not a full dump of one house. Three parameterized roles you copy, edit, and run.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```bash
git clone https://github.com/teamrustyonmars-byte/sentinel-install.git
cd sentinel-install
```

## Profiles (v0.1)

| Profile | What you get | Boxes |
|---------|----------------|-------|
| **minimal-web** | Apache (if missing) + dashboard HTML shell + `deploy-site.sh` | 1 web |
| **ai-desk** | Ollama + Open WebUI (compose) + [HouseCap](https://github.com/teamrustyonmars-byte/housecap) + desk helpers | 1 GPU/desk PC |
| **homelab-core** | minimal-web + ai-desk + simple LAN monitor + fleet apt scripts | 2–3 boxes |

More profiles may come later. Start with these three.

## Security model (scrubbed by design)

| Allowed in git | Never commit |
|----------------|--------------|
| `nodes.example.yaml` placeholders | Real `nodes.yaml` |
| `secrets.example.env` empty keys | Real passwords / tokens |
| Example `192.168.1.x` docs | Your live inventory |
| SSH **keys** recommended | Hard-coded `sudo` passwords |

Remote installs use `ssh` / `rsync`. Prefer **SSH keys** + passwordless `sudo` for the deploy user, or enter sudo on the box yourself.

```bash
# Optional local scrub check before you push a fork
./scripts/scrub-check.sh
```

## Quick start

```bash
cp configs/nodes.example.yaml configs/nodes.yaml
cp configs/secrets.example.env configs/secrets.env
chmod 600 configs/secrets.env

# edit YOUR hosts and users
nano configs/nodes.yaml

./install-profile.sh minimal-web   # or: ai-desk | homelab-core
```

## Layout

```text
sentinel-install/
  install-profile.sh
  configs/
    nodes.example.yaml
    secrets.example.env
  lib/common.sh
  roles/
    minimal-web/
    ai-desk/
    homelab-core/
  payloads/
    web-dashboard-shell/
  scripts/
    scrub-check.sh
```

## What each profile does

### minimal-web
- Ensures Apache on the **web** node  
- Deploys scrubbed `dashboard.html` + `index.html`  
- Installs `~/bin/deploy-site.sh` for later static deploys  

### ai-desk
- Compose: **Ollama** + **Open WebUI** under `~/sentinel-ai-desk`  
- Installs **HouseCap** (clone from GitHub if needed)  
- Desk tools: `desk-shot`, `desk-windows`, `audio-default-analog`  
- Companion path is **documented**, not forced (bring your own agent)  

Open WebUI ships with `WEBUI_AUTH=False` for a simple LAN lab — turn auth on before any wider exposure.

### homelab-core
- Runs **minimal-web** + **ai-desk**  
- **Infra monitor**: Python HTTP probes fleet hosts (`:8085` by default)  
- **Fleet apt**: check/apply helpers on each host in `fleet.hosts`  

## Not included (on purpose)

- Family / Care SMS data  
- Cloudflare tokens / tunnels  
- Camera credentials  
- Training datasets  
- One-click “clone my entire house”

## Requirements (operator machine)

- `bash`, `ssh`, `scp`, `rsync`, `python3`  
- Network reachability to targets  
- Targets: Debian / Ubuntu / Mint-ish with `apt` for package steps  

## Why this exists

Most “AI homelab” dumps either leak private inventory or glue everyone into one mega-compose. This pack is a **three-rung ladder** with a **scrub-first** security model and an optional desk capture path via HouseCap.

Use official Cap / CasaOS / your own Ansible where they fit. Use this when you want small, reviewable install profiles and no secret baggage.

## Related

- [HouseCap](https://github.com/teamrustyonmars-byte/housecap) — free Linux Cap-style screen recorder CLI  

## License

MIT for this pack’s scripts and payloads. Downstream services (Ollama, Open WebUI, Apache, ffmpeg) keep their own licenses.
