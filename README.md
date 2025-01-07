# Redis and Nginx Honeypot deployment script

## Overview
This script sets up a **Redis** and **Nginx** honeypot environment to simulate vulnerable services for monitoring and analysis purposes.

---

## Install 

```
su -
curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/h.sh -o install.sh
bash install.sh
```

---

## Features
1. **Automated Setup**
   - Installs dependencies like Redis, Nginx, and OpenSSL.
   - Creates and configures honeypot services.
2. **Redis Honeypot**
   - Isolated service user for Redis.
   - Simulates a database with fake user, product, and order data.
   - Locks down sensitive Redis commands for realistic behavior.
   - Configures systemd service files with strict permissions.
3. **Nginx Honeypot**
   - Generates SSL certificates for HTTPS configurations.
   - Serves multiple static and API error pages.
   - Fake HTTP Headers with vulnerable version (PHP, Varnish, Nginx, Symfony)
   - Embeds JavaScript calls to external tracking endpoints.
5. **Deception Modules**
   - Integrates with FortiDeceptor tools for enhanced deception.
6. **Log Management**
   - Clears and replaces logs and histories to obfuscate setup traces.

---

## Requirements
- Operating System: `Ubuntu 20.04` [see why](https://docs.fortinet.com/document/fortideceptor/6.0.0/fortideceptor-customization-cookbook/89327/introduction)
- Internet Access
- Root Privileges

---

Your contributions are always appreciated — feel free to help!
