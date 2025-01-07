# DirtyNginx — Redis & Nginx Honeypot

🇬🇧 **English** · [🇫🇷 Français](README.fr.md)

Deployment script that turns an Ubuntu host into a **deceptive honeypot**: a fake
**Redis** database and an **Nginx** server advertising old, "vulnerable" software.
An attacker who scans it finds juicy targets and an exposed database — all fake,
all logged.

## Demo — what an attacker sees

![Honeypot recon](docs/honeypot-recon.gif)

Recon against the honeypot: spoofed banners (**Symfony 2.7 / PHP 5.4.0**, Apache,
Varnish) and an "exposed" **Redis** full of fake e-commerce data. Every banner is
forged and every record is bait — meanwhile the attacker's recon is logged.

## Overview

The script sets up **Redis** and **Nginx** honeypot services that simulate
vulnerable systems for monitoring and analysis.

## Features

1. **Automated setup** — installs and configures Redis, Nginx, OpenSSL.
2. **Redis honeypot** — isolated service user, fake user/product/order data,
   sensitive commands locked down, hardened systemd unit.
3. **Nginx honeypot** — self-signed SSL, multiple static & API error pages, and
   **fake vulnerable version headers** (PHP, Varnish, Nginx, Symfony); embeds JS
   beacons to external tracking endpoints.
4. **Deception modules** — FortiDeceptor integration.
5. **Log management** — clears and replaces logs/histories to hide setup traces.

## Install

```bash
su -
curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/main/install.sh -o install.sh
bash install.sh
```

## Requirements

- OS: `Ubuntu 20.04` ([why](https://docs.fortinet.com/document/fortideceptor/6.0.0/fortideceptor-customization-cookbook/89327/introduction))
- Internet access · root privileges
