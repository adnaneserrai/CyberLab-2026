<#
.SYNOPSIS
   Script de déploiement automatisé (Infrastructure as Code) pour CyberLab 2026.
.DESCRIPTION
   Ce script automatise la création des utilisateurs dans l'Active Directory
   et injecte volontairement la vulnérabilité Kerberos (AS-REP Roasting)
   pour préparer l'environnement d'audit.
#>

# Importation du module Active Directorty
Import-Module ActiveDirectory

Write-Host "[*] Début du déploiement de l'infrastructure CyberLab..." -ForegroundColor Cyan

# 1. Création de l'utilisateur standard (le point de pivot)
Write-Host "[*] Création de l'utilisateur standard : jdupont"
if(Get-ADUser -Filter {SamAccountName -eq "jdupont"})
   {
      Write-Host "   -> L'utilisateur jdupont existe déjà. On passe." -ForegroundColor Yellow
   }
else
   {
   $PassDupont = ConvertTo-SecureString "CyberLab2026!" -AsPlainText -Force
   New-ADUser -Name "jdupont" -GivenName "Jean" -Surname "Dupont" -SamAccountName "jdupont" -UserPrincipalName "jdupont@cyber.local" -AccountPassword $PassDupont -Enabled $true
   }

# 2. Création du compte de service (la Cible de l'attaque)
Write-Host "[*] Création de service : svc_sql"
if(Get-ADUser -Filter {SamAccountName -eq "svc_sql"})
   {
      Write-Host "   -> L'utilisateur svc_sql existe déjà. On passe." -ForegroundColor Yellow
   }
else
   {
   $PassSQL = ConvertTo-SecureString "Oui1234!" -AsPlainText -Force
   New-ADUser -Name "svc_sql" -SamAccountName "svc_sql" -UserPrincipalName "svc_sql@cyber.local" -AccountPassword $PassSQL -Enabled $true
   }

# 3. INJECTION DE LA VULNERABILITE (AS-REP Roasting)
# C'est cette ligne de code spécifique qui rend le piratage possible
Write-Host "[!] Injection de la faille de sécurité Kerberos sur svc_sql..." -ForegroundColor Yellow
Set-ADAccountControl -Identity "svc_sql" -DoesNotRequirePreAuth $true