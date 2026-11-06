# CyberLab 2026: Zero to Dominance

A custom, minimalist Active Directory penetration testing lab, built from scratch and fully compromised through a complete attack chain — from an unauthenticated physical bypass to full Domain Dominance (DCSync).

Designed as a lightweight alternative to [GOAD](https://github.com/Orange-Cyberdefense/GOAD) for hardware-constrained environments (16 GB RAM), while still reproducing the core, real-world Active Directory misconfigurations attackers exploit in the wild.

> **Disclaimer:** Built for educational purposes and an authorized academic presentation. Every attack below was executed in a strictly isolated, local-only network with no internet access.

## Contents

- [Architecture](#architecture)
- [Deployment](#deployment)
- [Attack path](#attack-path)
- [Skills demonstrated](#skills-demonstrated)

## Architecture

Due to the 16 GB RAM constraint, the lab topology was reduced to the minimum number of machines needed to keep the core AD attack surface intact:

| Host | Role | OS | IP |
|---|---|---|---|
| `DC01` | Domain Controller (`cyber.local`) | Windows Server 2022 | `192.168.15.10` |
| `WIN10-CLIENT` | Target workstation | Windows 10 | `192.168.15.20` |
| `Attacker` | Offensive box | Kali Linux | `192.168.15.30` |

All three machines run on a completely isolated, Host-Only VMware network (`VMnet2`) with static IP routing — no bridge to the internet or the host's LAN.

## Deployment

Domain configuration and user provisioning are fully automated by [`Deploy-CyberLab.ps1`](Deploy-CyberLab.ps1), a PowerShell Infrastructure-as-Code script that:

1. Creates the standard pivot user (`jdupont`).
2. Creates the target service account (`svc_sql`).
3. Injects the intended misconfiguration: **Kerberos Pre-Authentication disabled** on `svc_sql`, opening the door to AS-REP Roasting.

## Attack path

### 1. Initial access — physical bypass (Utilman hijack)

Simulating physical access to the locked Windows 10 client: the Accessibility tool (`utilman.exe`) is replaced with `cmd.exe` via a mounted Windows installation ISO, giving an unauthenticated `NT AUTHORITY\SYSTEM` shell at the login screen.

**Result:** local `SYSTEM` shell, no credentials required.

### 2. Privilege escalation — AS-REP Roasting

Pivoting onto the network, the misconfigured `svc_sql` account is targeted to request a Kerberos ticket with no password, then the ticket is cracked offline.

```bash
impacket-GetNPUsers cyber.local/jdupont:'CyberLab2026!' -dc-ip 192.168.15.10 -request -format john -outputfile hash.txt
```

### 3. Credential harvesting — LSASS memory dump

With local admin privileges on the workstation, the `lsass.exe` process is dumped to extract the Domain Administrator's active session tokens.

```bash
nxc smb 192.168.15.20 -u Administrateur -p 'Oui1234!' -M lsassy
```

### 4. Domain dominance — DCSync

Using the recovered Domain Administrator NTLM hash, a Pass-the-Hash attack impersonates a rogue Domain Controller and requests full replication of the Active Directory database (`NTDS.dit`).

```bash
impacket-secretsdump cyber.local/Administrateur@192.168.15.10 -hashes 'aad3b435b51404eeaad3b435b51404ee:2a13076f6a2fcf8b68e60ff1f3fca101'
```

**Result:** total compromise of the `cyber.local` forest, including the `KRBTGT` hash.

### Network architecture

![CyberLab 2026 Architecture](Architecture%20Minilab_en.png)

## Skills demonstrated

- Active Directory deployment and IaC-style provisioning (PowerShell, `ActiveDirectory` module)
- Deliberate, documented misconfiguration of a real AD environment for training purposes
- End-to-end offensive kill chain: physical bypass → Kerberos abuse → credential dumping → domain takeover
- Tooling: Impacket, NetExec (`nxc`)/`lsassy`, John the Ripper, Mimikatz-style Pass-the-Hash

## Further reading

A full write-up of the build and the attack is kept in the slideshow: [`Cyberlab_slideshow.pdf`](Cyberlab_slideshow.pdf).
