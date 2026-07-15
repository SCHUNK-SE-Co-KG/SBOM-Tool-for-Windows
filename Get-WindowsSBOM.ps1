#Requires -Version 5.1
<#
.SYNOPSIS
    Windows SBOM Generator - CRA-konform (CycloneDX 1.6, BSI TR-03183-2 v2.1.0)
    Windows SBOM Generator - CRA-compliant (CycloneDX 1.6, BSI TR-03183-2 v2.1.0)

.DESCRIPTION
    [DE] Erzeugt eine vollstaendige Software Bill of Materials fuer ein installiertes
    Windows-System. Erfasst OS, Updates, Registry-Apps, Store-Apps, Windows-Features,
    Treiber und .NET-Runtimes.
    Ausgabe: CycloneDX 1.6 JSON + menschenlesbare Zusammenfassung.
    Konformitaet: BSI TR-03183-2 v2.1.0 (alle SHALL-Felder).

    [EN] Generates a complete Software Bill of Materials for an installed Windows system.
    Captures OS, updates, registry apps, store apps, Windows features, drivers and
    .NET runtimes.
    Output: CycloneDX 1.6 JSON + human-readable summary.
    Compliance: BSI TR-03183-2 v2.1.0 (all SHALL fields).

.PARAMETER OutputDir
    Zielverzeichnis. Standard: .\sbom-output
    Target directory. Default: .\sbom-output

.PARAMETER IncludeUserApps
    Auch HKCU-Apps erfassen.
    Also capture HKCU apps.

.PARAMETER IncludeDrivers
    Treiber-Inventar erfassen (kann langsam sein).
    Capture driver inventory (can be slow).

.PARAMETER IncludeStoreApps
    Microsoft Store / AppX-Pakete erfassen.
    Capture Microsoft Store / AppX packages.

.PARAMETER IncludeFeatures
    Windows Optional Features erfassen.
    Capture Windows Optional Features.

.PARAMETER All
    Alle optionalen Quellen aktivieren.
    Enable all optional sources.

.EXAMPLE
    .\Get-WindowsSBOM.ps1
    .\Get-WindowsSBOM.ps1 -All
    .\Get-WindowsSBOM.ps1 -OutputDir "C:\SBOMs" -IncludeDrivers -IncludeStoreApps
#>

[CmdletBinding()]
param(
    [string]$OutputDir = ".\sbom-output",
    [switch]$IncludeUserApps,
    [switch]$IncludeDrivers,
    [switch]$IncludeStoreApps,
    [switch]$IncludeFeatures,
    [switch]$All
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Script:ToolVersion = (Get-Content -Path (Join-Path $PSScriptRoot "VERSION") -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
if (-not $Script:ToolVersion) { $Script:ToolVersion = "1.1.0" }

# Kulturunabhaengige Formatierung erzwingen (laeuft auf allen Windows-Sprachen)
# Force culture-independent formatting (works on all Windows language versions)
[System.Threading.Thread]::CurrentThread.CurrentCulture   = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::InvariantCulture

if ($All) {
    $IncludeUserApps  = $true
    $IncludeDrivers   = $true
    $IncludeStoreApps = $true
    $IncludeFeatures  = $true
}

# =============================================================================
#  FIRMENDATEN / COMPANY DATA - SCHUNK Electronic Solutions GmbH
# =============================================================================

$CompanyInfo = @{
    Name    = "SCHUNK Electronic Solutions GmbH"
    Street  = "Am Tannwald 17"
    City    = "78112 St. Georgen im Schwarzwald"
    Country = "DE"
    Phone   = "+49-7725-9166-0"
    Fax     = "+49-7725-9166-5055"
    Email   = "electronic-solutions@de.schunk.com"
    URL     = "https://www.ses-support.de"
    HRB     = "HRB 602138, Amtsgericht Freiburg"
    GF      = "Ralf Vetter, Falk Baeurle"
    Parent  = "SCHUNK SE & Co. KG, Lauffen/Neckar"
}

# =============================================================================
#  LIZENZ-DATENBANK / LICENSE DATABASE (SPDX identifiers for known software)
# =============================================================================

$LicenseDB = @{

    # =================================================================
    #  ARCHIVER / KOMPRIMIERUNG / COMPRESSION
    # =================================================================
    "7-Zip"                  = "LGPL-2.1-or-later"
    "WinRAR"                 = "LicenseRef-Proprietary-WinRAR"
    "WinZip"                 = "LicenseRef-Proprietary-WinZip"
    "PeaZip"                 = "LGPL-3.0-or-later"
    "Bandizip"               = "LicenseRef-Proprietary-Bandisoft"

    # =================================================================
    #  BROWSER / BROWSERS
    # =================================================================
    "Google Chrome"          = "LicenseRef-Proprietary-Google"
    "Mozilla Firefox"        = "MPL-2.0"
    "Firefox"                = "MPL-2.0"
    "Microsoft Edge"         = "LicenseRef-Proprietary-Microsoft"
    "Brave"                  = "MPL-2.0"
    "Vivaldi"                = "LicenseRef-Proprietary-Vivaldi"
    "Opera"                  = "LicenseRef-Proprietary-Opera"
    "Tor Browser"            = "BSD-3-Clause"
    "Chromium"               = "BSD-3-Clause"

    # =================================================================
    #  EDITOREN / IDE / ENTWICKLUNG / EDITORS / IDE / DEVELOPMENT
    # =================================================================
    "Notepad++"              = "GPL-3.0-or-later"
    "Microsoft Visual Studio Code" = "MIT"
    "Visual Studio Code"     = "MIT"
    "Visual Studio Community" = "LicenseRef-Proprietary-Microsoft"
    "Visual Studio Professional" = "LicenseRef-Proprietary-Microsoft"
    "Visual Studio Enterprise" = "LicenseRef-Proprietary-Microsoft"
    "Sublime Text"           = "LicenseRef-Proprietary-SublimeHQ"
    "Atom"                   = "MIT"
    "Eclipse"                = "EPL-2.0"
    "IntelliJ IDEA"          = "Apache-2.0"
    "PyCharm"                = "Apache-2.0"
    "WebStorm"               = "LicenseRef-Proprietary-JetBrains"
    "JetBrains"              = "LicenseRef-Proprietary-JetBrains"
    "Android Studio"         = "Apache-2.0"
    "Arduino"                = "GPL-2.0-or-later"
    "Inno Setup"             = "LicenseRef-Proprietary-InnoSetup"
    "NSIS"                   = "Zlib"

    # =================================================================
    #  VERSIONSKONTROLLE / VERSION CONTROL
    # =================================================================
    "Git"                    = "GPL-2.0-only"
    "Git for Windows"        = "GPL-2.0-only"
    "TortoiseGit"            = "GPL-2.0-only"
    "TortoiseSVN"            = "GPL-2.0-or-later"
    "Subversion"             = "Apache-2.0"
    "GitHub Desktop"         = "MIT"
    "GitKraken"              = "LicenseRef-Proprietary-Axosoft"
    "SourceTree"             = "LicenseRef-Proprietary-Atlassian"

    # =================================================================
    #  PROGRAMMIERSPRACHEN / RUNTIMES / PROGRAMMING LANGUAGES / RUNTIMES
    # =================================================================
    "Node.js"                = "MIT"
    "Python"                 = "PSF-2.0"
    "Ruby"                   = "BSD-2-Clause"
    "Perl"                   = "Artistic-2.0"
    "PHP"                    = "PHP-3.01"
    "Go"                     = "BSD-3-Clause"
    "Rust"                   = "Apache-2.0 OR MIT"
    "Erlang"                 = "Apache-2.0"
    "R for Windows"          = "GPL-2.0-or-later"
    "Julia"                  = "MIT"
    "Lua"                    = "MIT"
    "Tcl"                    = "TCL"
    "XAMPP"                  = "GPL-2.0-or-later"

    # Java-Distributionen / Java distributions
    "Amazon Corretto"        = "GPL-2.0-only WITH Classpath-exception-2.0"
    "Eclipse Temurin"        = "GPL-2.0-only WITH Classpath-exception-2.0"
    "Oracle Java"            = "LicenseRef-Proprietary-Oracle-NFTC"
    "Oracle JDK"             = "LicenseRef-Proprietary-Oracle-NFTC"
    "Azul Zulu"              = "GPL-2.0-only WITH Classpath-exception-2.0"
    "Liberica JDK"           = "GPL-2.0-only WITH Classpath-exception-2.0"
    "SapMachine"             = "GPL-2.0-only WITH Classpath-exception-2.0"
    "GraalVM"                = "GPL-2.0-only WITH Classpath-exception-2.0"

    # .NET / Microsoft Runtimes (MIT-lizenziert / MIT-licensed)
    "Microsoft .NET"         = "MIT"
    "Microsoft ASP.NET"      = "MIT"
    "Microsoft Windows Desktop Runtime" = "MIT"
    "Microsoft .NET SDK"     = "MIT"
    "Microsoft .NET Runtime"  = "MIT"
    "Microsoft .NET Core"    = "MIT"
    "Microsoft .NET Framework" = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Visual C++"   = "LicenseRef-Proprietary-Microsoft-Redist"

    # =================================================================
    #  DATENBANKEN / DATABASES
    # =================================================================
    "PostgreSQL"             = "PostgreSQL"
    "MariaDB"                = "GPL-2.0-only"
    "MySQL"                  = "GPL-2.0-only"
    "SQLite"                 = "blessing"
    "MongoDB"                = "SSPL-1.0"
    "Redis"                  = "RSALv2"
    "SQL Server"             = "LicenseRef-Proprietary-Microsoft"
    "Oracle Database"        = "LicenseRef-Proprietary-Oracle"
    "DBeaver"                = "Apache-2.0"
    "HeidiSQL"               = "GPL-2.0-or-later"
    "pgAdmin"                = "PostgreSQL"
    "DB Browser for SQLite"  = "MPL-2.0"

    # =================================================================
    #  NETZWERK / REMOTE / VPN / NETWORK / REMOTE / VPN
    # =================================================================
    "PuTTY"                  = "MIT"
    "WinSCP"                 = "GPL-3.0-only"
    "FileZilla"              = "GPL-2.0-or-later"
    "Wireshark"              = "GPL-2.0-only"
    "Nmap"                   = "LicenseRef-scancode-nmap-public-source"
    "WireGuard"              = "GPL-2.0-only"
    "OpenVPN"                = "GPL-2.0-only"
    "Angry IP Scanner"       = "GPL-2.0-or-later"
    "Advanced IP Scanner"    = "LicenseRef-Freeware-Famatech"
    "TeamViewer"             = "LicenseRef-Proprietary-TeamViewer"
    "AnyDesk"                = "LicenseRef-Proprietary-AnyDesk"
    "RealVNC"                = "LicenseRef-Proprietary-RealVNC"
    "TightVNC"               = "GPL-2.0-or-later"
    "mRemoteNG"              = "GPL-2.0-or-later"
    "Remmina"                = "GPL-2.0-or-later"
    "Termius"                = "LicenseRef-Proprietary-Termius"
    "MobaXterm"              = "LicenseRef-Proprietary-Mobatek"
    "Fiddler"                = "LicenseRef-Proprietary-Telerik"
    "Postman"                = "LicenseRef-Proprietary-Postman"
    "Insomnia"               = "MIT"
    "curl"                   = "curl"
    "OpenSSH"                = "SSH-OpenSSH"
    "Tailscale"              = "BSD-3-Clause"

    # =================================================================
    #  GRAFIK / DESIGN / MEDIEN / GRAPHICS / DESIGN / MEDIA
    # =================================================================
    "GIMP"                   = "GPL-3.0-or-later"
    "Inkscape"               = "GPL-2.0-or-later"
    "Blender"                = "GPL-2.0-or-later"
    "Krita"                  = "GPL-3.0-only"
    "Scribus"                = "GPL-2.0-or-later"
    "darktable"              = "GPL-3.0-or-later"
    "RawTherapee"            = "GPL-3.0-or-later"
    "digiKam"                = "GPL-2.0-or-later"
    "Paint.NET"              = "LicenseRef-Proprietary-PaintNET"
    "IrfanView"              = "LicenseRef-Proprietary-IrfanView"
    "XnView"                 = "LicenseRef-Freeware-XnSoft"
    "Greenshot"              = "GPL-3.0-or-later"
    "ShareX"                 = "GPL-3.0-or-later"
    "Snagit"                 = "LicenseRef-Proprietary-TechSmith"
    "draw.io"                = "Apache-2.0"
    "diagrams.net"           = "Apache-2.0"
    "Adobe Acrobat"          = "LicenseRef-Proprietary-Adobe"
    "Adobe Creative"         = "LicenseRef-Proprietary-Adobe"
    "Adobe Photoshop"        = "LicenseRef-Proprietary-Adobe"
    "Adobe Illustrator"      = "LicenseRef-Proprietary-Adobe"
    "Adobe InDesign"         = "LicenseRef-Proprietary-Adobe"
    "Adobe Premiere"         = "LicenseRef-Proprietary-Adobe"
    "Adobe After Effects"    = "LicenseRef-Proprietary-Adobe"
    "Adobe Reader"           = "LicenseRef-Proprietary-Adobe"
    "Adobe Lightroom"        = "LicenseRef-Proprietary-Adobe"
    "CorelDRAW"              = "LicenseRef-Proprietary-Corel"
    "Corel"                  = "LicenseRef-Proprietary-Corel"

    # =================================================================
    #  AUDIO / VIDEO / AUDIO / VIDEO
    # =================================================================
    "VLC media player"       = "GPL-2.0-or-later"
    "Audacity"               = "GPL-3.0-only"
    "OBS Studio"             = "GPL-2.0-or-later"
    "HandBrake"              = "GPL-2.0-only"
    "FFmpeg"                 = "LGPL-2.1-or-later"
    "foobar2000"             = "LicenseRef-Freeware-foobar2000"
    "MPC-HC"                 = "GPL-3.0-only"
    "mpv"                    = "GPL-2.0-or-later"
    "Shotcut"                = "GPL-3.0-or-later"
    "Kdenlive"               = "GPL-3.0-or-later"
    "DaVinci Resolve"        = "LicenseRef-Proprietary-Blackmagic"
    "Spotify"                = "LicenseRef-Proprietary-Spotify"
    "iTunes"                 = "LicenseRef-Proprietary-Apple"
    "Zoom"                   = "LicenseRef-Proprietary-Zoom"
    "CDBurnerXP"             = "LicenseRef-Freeware"

    # =================================================================
    #  OFFICE / PRODUKTIVITAET / OFFICE / PRODUCTIVITY
    # =================================================================
    "LibreOffice"            = "MPL-2.0"
    "OpenOffice"             = "Apache-2.0"
    "Apache OpenOffice"      = "Apache-2.0"
    "SumatraPDF"             = "GPL-3.0-only"
    "Foxit Reader"           = "LicenseRef-Proprietary-Foxit"
    "Foxit PDF"              = "LicenseRef-Proprietary-Foxit"
    "PDF24"                  = "LicenseRef-Freeware-GeekSoftware"
    "PDFsam"                 = "AGPL-3.0-only"
    "Calibre"                = "GPL-3.0-only"
    "Thunderbird"            = "MPL-2.0"
    "Mozilla Thunderbird"    = "MPL-2.0"
    "KeePass"                = "GPL-2.0-or-later"
    "KeePassXC"              = "GPL-3.0-or-later"
    "Bitwarden"              = "GPL-3.0-only"
    "1Password"              = "LicenseRef-Proprietary-1Password"
    "LastPass"               = "LicenseRef-Proprietary-LastPass"
    "Everything"             = "LicenseRef-Freeware-voidtools"
    "Onetastic"              = "LicenseRef-Proprietary-ATAY"
    "Notion"                 = "LicenseRef-Proprietary-Notion"
    "Obsidian"               = "LicenseRef-Proprietary-Obsidian"
    "Typora"                 = "LicenseRef-Proprietary-Typora"
    "Zotero"                 = "AGPL-3.0-only"

    # =================================================================
    #  MICROSOFT - Produkte / Products
    # =================================================================
    "Microsoft 365"          = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Office"       = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Word"         = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Excel"        = "LicenseRef-Proprietary-Microsoft"
    "Microsoft PowerPoint"   = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Outlook"      = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Access"       = "LicenseRef-Proprietary-Microsoft"
    "Microsoft OneDrive"     = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Teams"        = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Project"      = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Visio"        = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Intune"       = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Help Viewer"  = "LicenseRef-Proprietary-Microsoft"
    "Microsoft ReportViewer" = "LicenseRef-Proprietary-Microsoft"
    "Microsoft System CLR"   = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Device Inventory" = "LicenseRef-Proprietary-Microsoft"
    "Microsoft SQL Server"   = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Power BI"     = "LicenseRef-Proprietary-Microsoft"
    "Microsoft PowerToys"    = "MIT"
    "PowerToys"              = "MIT"
    "Windows Terminal"       = "MIT"
    "Windows Autopatch"      = "LicenseRef-Proprietary-Microsoft"
    "Windows App SDK"        = "MIT"

    # =================================================================
    #  GOOGLE / GOOGLE
    # =================================================================
    "Google Drive"           = "LicenseRef-Proprietary-Google"
    "Google Earth"           = "LicenseRef-Proprietary-Google"
    "Google Backup"          = "LicenseRef-Proprietary-Google"
    "Android SDK"            = "Apache-2.0"

    # =================================================================
    #  VIRTUALISIERUNG / CONTAINER / VIRTUALIZATION / CONTAINERS
    # =================================================================
    "VMware Workstation"     = "LicenseRef-Proprietary-VMware"
    "VMware Player"          = "LicenseRef-Proprietary-VMware"
    "VMware Tools"           = "LicenseRef-Proprietary-VMware"
    "VirtualBox"             = "GPL-3.0-only"
    "Oracle VM VirtualBox"   = "GPL-3.0-only"
    "Docker Desktop"         = "LicenseRef-Proprietary-Docker"
    "Docker"                 = "Apache-2.0"
    "Podman"                 = "Apache-2.0"
    "Vagrant"                = "BSL-1.1"
    "Terraform"              = "BSL-1.1"
    "Hyper-V"                = "LicenseRef-Proprietary-Microsoft"
    "QEMU"                   = "GPL-2.0-only"
    "WSL"                    = "LicenseRef-Proprietary-Microsoft"
    "HaXM"                   = "LicenseRef-Proprietary-Intel"

    # =================================================================
    #  SICHERHEIT / ANTIVIRUS / SECURITY / ANTIVIRUS
    # =================================================================
    "Windows Defender"       = "LicenseRef-Proprietary-Microsoft"
    "Kaspersky"              = "LicenseRef-Proprietary-Kaspersky"
    "Norton"                 = "LicenseRef-Proprietary-NortonLifeLock"
    "Avast"                  = "LicenseRef-Proprietary-Avast"
    "AVG"                    = "LicenseRef-Proprietary-AVG"
    "Bitdefender"            = "LicenseRef-Proprietary-Bitdefender"
    "ESET"                   = "LicenseRef-Proprietary-ESET"
    "Malwarebytes"           = "LicenseRef-Proprietary-Malwarebytes"
    "ClamWin"                = "GPL-2.0-or-later"
    "CrowdStrike"            = "LicenseRef-Proprietary-CrowdStrike"
    "Sophos"                 = "LicenseRef-Proprietary-Sophos"
    "Trend Micro"            = "LicenseRef-Proprietary-TrendMicro"
    "Carbon Black"           = "LicenseRef-Proprietary-VMware"
    "Local Administrator Password Solution" = "LicenseRef-Proprietary-Microsoft"

    # =================================================================
    #  SYSTEM-TOOLS / UTILITIES / SYSTEM TOOLS / UTILITIES
    # =================================================================
    "AutoHotkey"             = "GPL-2.0-or-later"
    "Windhawk"               = "GPL-3.0-or-later"
    "Hidden Start"           = "LicenseRef-Proprietary-NTWind"
    "DisplayFusion"          = "LicenseRef-Proprietary-BinaryFortress"
    "Sysinternals"           = "LicenseRef-Proprietary-Microsoft"
    "Process Explorer"       = "LicenseRef-Proprietary-Microsoft"
    "Autoruns"               = "LicenseRef-Proprietary-Microsoft"
    "BleachBit"              = "GPL-3.0-or-later"
    "CCleaner"               = "LicenseRef-Proprietary-Piriform"
    "TreeSize"               = "LicenseRef-Proprietary-JAMSoftware"
    "WinDirStat"             = "GPL-2.0-or-later"
    "WizTree"                = "LicenseRef-Freeware-Antibody"
    "Rufus"                  = "GPL-3.0-or-later"
    "Etcher"                 = "Apache-2.0"
    "balenaEtcher"           = "Apache-2.0"
    "ImgBurn"                = "LicenseRef-Freeware-LIGHTNING"
    "CPU-Z"                  = "LicenseRef-Freeware-CPUID"
    "GPU-Z"                  = "LicenseRef-Freeware-TechPowerUp"
    "HWiNFO"                 = "LicenseRef-Freeware-HWiNFO"
    "CrystalDiskInfo"        = "MIT"
    "CrystalDiskMark"        = "MIT"
    "Speccy"                 = "LicenseRef-Proprietary-Piriform"
    "Recuva"                 = "LicenseRef-Proprietary-Piriform"
    "Total Commander"        = "LicenseRef-Proprietary-Ghisler"
    "Directory Opus"         = "LicenseRef-Proprietary-GPSoftware"
    "Double Commander"       = "GPL-2.0-or-later"
    "FastCopy"               = "GPL-3.0-or-later"
    "Revo Uninstaller"       = "LicenseRef-Proprietary-VSRevo"

    # =================================================================
    #  REMOTE DESKTOP / CITRIX / KOMMUNIKATION / COMMUNICATION
    # =================================================================
    "Citrix"                 = "LicenseRef-Proprietary-Citrix"
    "Citrix Workspace"       = "LicenseRef-Proprietary-Citrix"
    "Citrix Secure Access"   = "LicenseRef-Proprietary-Citrix"
    "Citrix Browser"         = "LicenseRef-Proprietary-Citrix"
    "Jabra Direct"           = "LicenseRef-Proprietary-GN-Audio"
    "Jabra"                  = "LicenseRef-Proprietary-GN-Audio"
    "Logi Options"           = "LicenseRef-Proprietary-Logitech"
    "Logi Plugin"            = "LicenseRef-Proprietary-Logitech"
    "Logitech"               = "LicenseRef-Proprietary-Logitech"
    "ClickShare"             = "LicenseRef-Proprietary-Barco"
    "Barco"                  = "LicenseRef-Proprietary-Barco"
    "Slack"                  = "LicenseRef-Proprietary-Slack"
    "Discord"                = "LicenseRef-Proprietary-Discord"
    "Signal"                 = "AGPL-3.0-only"
    "Telegram"               = "GPL-2.0-or-later"
    "Element"                = "Apache-2.0"

    # =================================================================
    #  3D-DRUCK / CAD / CAM / CAE / 3D PRINTING / CAD / CAM / CAE
    # =================================================================
    "SOLIDWORKS"             = "LicenseRef-Proprietary-DassaultSystemes"
    "Dassault"               = "LicenseRef-Proprietary-DassaultSystemes"
    "AutoCAD"                = "LicenseRef-Proprietary-Autodesk"
    "Autodesk"               = "LicenseRef-Proprietary-Autodesk"
    "Inventor"               = "LicenseRef-Proprietary-Autodesk"
    "Fusion 360"             = "LicenseRef-Proprietary-Autodesk"
    "FreeCAD"                = "LGPL-2.1-or-later"
    "OpenSCAD"               = "GPL-2.0-or-later"
    "Cura"                   = "LGPL-3.0-or-later"
    "PrusaSlicer"            = "AGPL-3.0-or-later"
    "Bambu Studio"           = "AGPL-3.0-or-later"
    "OrcaSlicer"             = "AGPL-3.0-or-later"
    "KiCad"                  = "GPL-3.0-or-later"
    "EAGLE"                  = "LicenseRef-Proprietary-Autodesk"
    "Altium"                 = "LicenseRef-Proprietary-Altium"
    "CATIA"                  = "LicenseRef-Proprietary-DassaultSystemes"
    "Siemens NX"             = "LicenseRef-Proprietary-Siemens"
    "Solid Edge"             = "LicenseRef-Proprietary-Siemens"
    "PTC Creo"               = "LicenseRef-Proprietary-PTC"
    "ANSYS"                  = "LicenseRef-Proprietary-ANSYS"
    "MATLAB"                 = "LicenseRef-Proprietary-MathWorks"
    "LabVIEW"                = "LicenseRef-Proprietary-NI"

    # =================================================================
    #  INDUSTRIEAUTOMATION / SPS / HMI / INDUSTRIAL AUTOMATION / PLC / HMI
    # =================================================================
    "Beckhoff TwinCAT"       = "LicenseRef-Proprietary-Beckhoff"
    "TwinCAT"                = "LicenseRef-Proprietary-Beckhoff"
    "Beckhoff"               = "LicenseRef-Proprietary-Beckhoff"
    "Siemens TIA"            = "LicenseRef-Proprietary-Siemens"
    "TIA Portal"             = "LicenseRef-Proprietary-Siemens"
    "STEP 7"                 = "LicenseRef-Proprietary-Siemens"
    "WinCC"                  = "LicenseRef-Proprietary-Siemens"
    "Siemens Automation"     = "LicenseRef-Proprietary-Siemens"
    "Siemens PLCSIM"         = "LicenseRef-Proprietary-Siemens"
    "CODESYS"                = "LicenseRef-Proprietary-CODESYS"
    "ABB RobotStudio"        = "LicenseRef-Proprietary-ABB"
    "ABB"                    = "LicenseRef-Proprietary-ABB"
    "KUKA"                   = "LicenseRef-Proprietary-KUKA"
    "FANUC"                  = "LicenseRef-Proprietary-FANUC"
    "Schneider Electric"     = "LicenseRef-Proprietary-SchneiderElectric"
    "EcoStruxure"            = "LicenseRef-Proprietary-SchneiderElectric"
    "Rockwell"               = "LicenseRef-Proprietary-RockwellAutomation"
    "Allen-Bradley"          = "LicenseRef-Proprietary-RockwellAutomation"
    "RSLogix"                = "LicenseRef-Proprietary-RockwellAutomation"
    "Studio 5000"            = "LicenseRef-Proprietary-RockwellAutomation"
    "Phoenix Contact"        = "LicenseRef-Proprietary-PhoenixContact"
    "PLCnext"                = "LicenseRef-Proprietary-PhoenixContact"
    "OMRON"                  = "LicenseRef-Proprietary-OMRON"
    "Traceability Toolbox"   = "LicenseRef-Proprietary-OMRON"
    "Mitsubishi GX"          = "LicenseRef-Proprietary-MitsubishiElectric"
    "Mitsubishi"             = "LicenseRef-Proprietary-MitsubishiElectric"
    "UaGateway"              = "LicenseRef-Proprietary-UnifiedAutomation"
    "Unified Automation"     = "LicenseRef-Proprietary-UnifiedAutomation"
    "OPC UA"                 = "LicenseRef-Proprietary-OPCFoundation"
    "Kepware"                = "LicenseRef-Proprietary-PTC"
    "Node-RED"               = "Apache-2.0"
    "Grafana"                = "AGPL-3.0-only"
    "InfluxDB"               = "MIT"
    "Mosquitto"              = "EPL-2.0"
    "MQTT"                   = "EPL-2.0"
    "SCHUNK"                 = "LicenseRef-Proprietary-SCHUNK"
    "SCHUNK PassEnc"         = "LicenseRef-Proprietary-SCHUNK"

    # =================================================================
    #  HARDWARE-HERSTELLER / HARDWARE VENDORS (Treiber & Tools / Drivers & Tools)
    # =================================================================
    "Dell"                   = "LicenseRef-Proprietary-Dell"
    "Dell Command"           = "LicenseRef-Proprietary-Dell"
    "Dell SupportAssist"     = "LicenseRef-Proprietary-Dell"
    "Dell Core Services"     = "LicenseRef-Proprietary-Dell"
    "Dell Display"           = "LicenseRef-Proprietary-Dell"
    "Dell Peripheral"        = "LicenseRef-Proprietary-Dell"
    "HP "                    = "LicenseRef-Proprietary-HP"
    "Hewlett-Packard"        = "LicenseRef-Proprietary-HP"
    "Lenovo"                 = "LicenseRef-Proprietary-Lenovo"
    "Samsung"                = "LicenseRef-Proprietary-Samsung"
    "Samsung Magician"       = "LicenseRef-Proprietary-Samsung"
    "Intel"                  = "LicenseRef-Proprietary-Intel"
    "Intel(R)"               = "LicenseRef-Proprietary-Intel"
    "NVIDIA"                 = "LicenseRef-Proprietary-NVIDIA"
    "GeForce"                = "LicenseRef-Proprietary-NVIDIA"
    "AMD"                    = "LicenseRef-Proprietary-AMD"
    "Radeon"                 = "LicenseRef-Proprietary-AMD"
    "Realtek"                = "LicenseRef-Proprietary-Realtek"
    "Broadcom"               = "LicenseRef-Proprietary-Broadcom"
    "Qualcomm"               = "LicenseRef-Proprietary-Qualcomm"
    "Synaptics"              = "LicenseRef-Proprietary-Synaptics"
    "Conexant"               = "LicenseRef-Proprietary-Conexant"
    "Waves"                  = "LicenseRef-Proprietary-Waves"
    "Synology"               = "LicenseRef-Proprietary-Synology"

    # =================================================================
    #  CLOUD / BACKUP / SPEICHER / CLOUD / BACKUP / STORAGE
    # =================================================================
    "Dropbox"                = "LicenseRef-Proprietary-Dropbox"
    "Nextcloud"              = "AGPL-3.0-or-later"
    "ownCloud"               = "AGPL-3.0-or-later"
    "Veeam"                  = "LicenseRef-Proprietary-Veeam"
    "Acronis"                = "LicenseRef-Proprietary-Acronis"
    "Duplicati"              = "LGPL-2.1-only"
    "Restic"                 = "BSD-2-Clause"
    "rclone"                 = "MIT"
    "BorgBackup"             = "BSD-3-Clause"
    "Macrium"                = "LicenseRef-Proprietary-Macrium"
    "AOMEI"                  = "LicenseRef-Proprietary-AOMEI"
    "EaseUS"                 = "LicenseRef-Proprietary-EaseUS"

    # =================================================================
    #  DIVERSE / MISCELLANEOUS
    # =================================================================
    "GLKVM"                  = "LicenseRef-Proprietary-GLiNet"
    "Kubernetes"             = "Apache-2.0"
    "kubectl"                = "Apache-2.0"
    "Helm"                   = "Apache-2.0"
    "Ansible"                = "GPL-3.0-only"
    "Nginx"                  = "BSD-2-Clause"
    "Apache HTTP"            = "Apache-2.0"
    "Tomcat"                 = "Apache-2.0"
    "Elasticsearch"          = "SSPL-1.0"
    "Prometheus"             = "Apache-2.0"
    "Jenkins"                = "MIT"
    "Nexus Repository"       = "EPL-1.0"
    "SonarQube"              = "LGPL-3.0-only"
    "Mattermost"             = "MIT"
    "Jira"                   = "LicenseRef-Proprietary-Atlassian"
    "Confluence"             = "LicenseRef-Proprietary-Atlassian"
    "Atlassian"              = "LicenseRef-Proprietary-Atlassian"

    # =================================================================
    #  SECURITY / EDR / XDR / FIREWALL / VPN (Erweiterung / Extended)
    # =================================================================
    "Zscaler"                = "LicenseRef-Proprietary-Zscaler"
    "SentinelOne"            = "LicenseRef-Proprietary-SentinelOne"
    "Palo Alto"              = "LicenseRef-Proprietary-PaloAlto"
    "GlobalProtect"          = "LicenseRef-Proprietary-PaloAlto"
    "Cortex"                 = "LicenseRef-Proprietary-PaloAlto"
    "Fortinet"               = "LicenseRef-Proprietary-Fortinet"
    "FortiClient"            = "LicenseRef-Proprietary-Fortinet"
    "FortiEDR"               = "LicenseRef-Proprietary-Fortinet"
    "Check Point"            = "LicenseRef-Proprietary-CheckPoint"
    "McAfee"                 = "LicenseRef-Proprietary-McAfee"
    "Trellix"                = "LicenseRef-Proprietary-Trellix"
    "Cylance"                = "LicenseRef-Proprietary-Blackberry"
    "Symantec"               = "LicenseRef-Proprietary-Broadcom"
    "Cisco AnyConnect"       = "LicenseRef-Proprietary-Cisco"
    "Cisco Secure"           = "LicenseRef-Proprietary-Cisco"
    "Cisco"                  = "LicenseRef-Proprietary-Cisco"
    "Ivanti"                 = "LicenseRef-Proprietary-Ivanti"
    "Pulse Secure"           = "LicenseRef-Proprietary-Ivanti"
    "WatchGuard"             = "LicenseRef-Proprietary-WatchGuard"
    "Barracuda"              = "LicenseRef-Proprietary-Barracuda"
    "Arctic Wolf"            = "LicenseRef-Proprietary-ArcticWolf"
    "Rapid7"                 = "LicenseRef-Proprietary-Rapid7"
    "Qualys"                 = "LicenseRef-Proprietary-Qualys"
    "Tenable"                = "LicenseRef-Proprietary-Tenable"
    "Nessus"                 = "LicenseRef-Proprietary-Tenable"
    "Splunk"                 = "LicenseRef-Proprietary-Splunk"
    "Elastic Agent"          = "SSPL-1.0"
    "Wazuh"                  = "GPL-2.0-only"
    "OSSEC"                  = "GPL-2.0-only"
    "Snort"                  = "GPL-2.0-only"
    "Suricata"               = "GPL-2.0-only"

    # =================================================================
    #  BUILD-TOOLS / PAKETMANAGER / DEVOPS / PACKAGE MANAGERS (Erweiterung / Extended)
    # =================================================================
    "Gradle"                 = "Apache-2.0"
    "Maven"                  = "Apache-2.0"
    "Ant"                    = "Apache-2.0"
    "npm"                    = "Artistic-2.0"
    "Yarn"                   = "BSD-2-Clause"
    "pnpm"                   = "MIT"
    "Bun"                    = "MIT"
    "Deno"                   = "MIT"
    "CMake"                  = "BSD-3-Clause"
    "Ninja"                  = "Apache-2.0"
    "Bazel"                  = "Apache-2.0"
    "Bruno"                  = "MIT"
    "SoapUI"                 = "EUPL-1.1"
    "Hoppscotch"             = "MIT"
    "GitLab Runner"          = "MIT"
    "GitHub CLI"             = "MIT"
    "gh "                    = "MIT"
    "act"                    = "MIT"
    "Chocolatey"             = "Apache-2.0"
    "Scoop"                  = "Unlicense"
    "winget"                 = "MIT"
    "NuGet"                  = "Apache-2.0"
    "pip"                    = "MIT"
    "Cargo"                  = "Apache-2.0 OR MIT"
    "Composer"               = "MIT"
    "Bundler"                = "MIT"

    # =================================================================
    #  CURSOR / WEITERE EDITOREN / MORE EDITORS
    # =================================================================
    "Cursor"                 = "LicenseRef-Proprietary-Anysphere"
    "Windsurf"               = "LicenseRef-Proprietary-Codeium"
    "Codeium"                = "LicenseRef-Proprietary-Codeium"
    "GitHub Copilot"         = "LicenseRef-Proprietary-GitHub"
    "Copilot"                = "LicenseRef-Proprietary-GitHub"
    "Tabnine"                = "LicenseRef-Proprietary-Tabnine"
    "Zed"                    = "GPL-3.0-or-later"
    "Neovim"                 = "Apache-2.0"
    "Vim"                    = "Vim"
    "Emacs"                  = "GPL-3.0-or-later"
    "Helix"                  = "MPL-2.0"

    # =================================================================
    #  MONITORING / OBSERVABILITY / LOGGING / MONITORING / OBSERVABILITY / LOGGING
    # =================================================================
    "Datadog"                = "LicenseRef-Proprietary-Datadog"
    "New Relic"              = "LicenseRef-Proprietary-NewRelic"
    "Dynatrace"              = "LicenseRef-Proprietary-Dynatrace"
    "AppDynamics"            = "LicenseRef-Proprietary-Cisco"
    "Nagios"                 = "GPL-2.0-only"
    "Zabbix"                 = "GPL-2.0-or-later"
    "Icinga"                 = "GPL-2.0-or-later"
    "Telegraf"               = "MIT"
    "Fluentd"                = "Apache-2.0"
    "Filebeat"               = "SSPL-1.0"
    "Logstash"               = "SSPL-1.0"
    "Kibana"                 = "SSPL-1.0"

    # =================================================================
    #  WEITERE GAENGIGE WINDOWS-SOFTWARE / MORE COMMON WINDOWS SOFTWARE
    # =================================================================
    "Acrobat"                = "LicenseRef-Proprietary-Adobe"
    "Nitro PDF"              = "LicenseRef-Proprietary-Nitro"
    "Power Automate"         = "LicenseRef-Proprietary-Microsoft"
    "Power BI Desktop"       = "LicenseRef-Proprietary-Microsoft"
    "Skype"                  = "LicenseRef-Proprietary-Microsoft"
    "WhatsApp"               = "LicenseRef-Proprietary-Meta"
    "Webex"                  = "LicenseRef-Proprietary-Cisco"
    "GoTo"                   = "LicenseRef-Proprietary-GoTo"
    "LogMeIn"                = "LicenseRef-Proprietary-GoTo"
    "Ninite"                 = "LicenseRef-Proprietary-Ninite"
    "Chocolatey GUI"         = "Apache-2.0"
    "WinMerge"               = "GPL-2.0-or-later"
    "Beyond Compare"         = "LicenseRef-Proprietary-ScooterSoftware"
    "Meld"                   = "GPL-2.0-or-later"
    "HxD"                    = "LicenseRef-Freeware-MhNexus"
    "Winaero Tweaker"        = "LicenseRef-Freeware-Winaero"
    "PowerShell"             = "MIT"
    "Oh My Posh"             = "MIT"
    "Starship"               = "ISC"
    "ripgrep"                = "Unlicense OR MIT"
    "fd"                     = "Apache-2.0 OR MIT"
    "fzf"                    = "MIT"
    "bat"                    = "Apache-2.0 OR MIT"
    "delta"                  = "MIT"
    "jq"                     = "MIT"
    "yq"                     = "MIT"
    "Pandoc"                 = "GPL-2.0-or-later"
    "LaTeX"                  = "LPPL-1.3c"
    "MiKTeX"                 = "LPPL-1.3c"
    "TeX Live"               = "LPPL-1.3c"

    # =================================================================
    #  PUBLISHER-BASIERTE FALLBACKS / PUBLISHER-BASED FALLBACKS (wenn Name nicht matched / when name doesn't match)
    # =================================================================
    "Microsoft"              = "LicenseRef-Proprietary-Microsoft"
    "Microsoft Corporation"  = "LicenseRef-Proprietary-Microsoft"
    "Windows"                = "LicenseRef-Proprietary-Microsoft"
    "Google"                 = "LicenseRef-Proprietary-Google"
    "Apple"                  = "LicenseRef-Proprietary-Apple"
    "Adobe"                  = "LicenseRef-Proprietary-Adobe"
    "Oracle"                 = "LicenseRef-Proprietary-Oracle"
    "SAP"                    = "LicenseRef-Proprietary-SAP"
    "Siemens"                = "LicenseRef-Proprietary-Siemens"
    "Bosch"                  = "LicenseRef-Proprietary-Bosch"
}

# =============================================================================
#  HILFSFUNKTIONEN / HELPER FUNCTIONS
# =============================================================================

function Get-Timestamp { [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") }
function New-Uuid { [Guid]::NewGuid().ToString() }

function Resolve-License {
    param([string]$AppName, [string]$Publisher)
    # Exakte Treffer zuerst, dann Prefix-Match / Exact matches first, then prefix match
    foreach ($key in $LicenseDB.Keys) {
        if ($AppName -eq $key) { return $LicenseDB[$key] }
    }
    foreach ($key in ($LicenseDB.Keys | Sort-Object { $_.Length } -Descending)) {
        if ($AppName -like "$key*") { return $LicenseDB[$key] }
    }
    # Publisher-basierter Fallback / Publisher-based fallback
    if ($Publisher) {
        foreach ($key in $LicenseDB.Keys) {
            if ($Publisher -like "$key*") { return $LicenseDB[$key] }
        }
    }
    return "NOASSERTION"
}

function Get-SHA512Safe {
    param([string]$Path)
    if ($Path -and (Test-Path $Path -PathType Leaf)) {
        try {
            $h = Get-FileHash -Path $Path -Algorithm SHA512 -ErrorAction SilentlyContinue
            if ($h) { return $h.Hash.ToLowerInvariant() }
        } catch {}
    }
    return $null
}

function ConvertTo-Purl {
    param([string]$Publisher, [string]$Name, [string]$Version)
    $ns   = if ($Publisher) { [Uri]::EscapeDataString($Publisher.Trim()) } else { "unknown" }
    $comp = [Uri]::EscapeDataString($Name.Trim())
    $ver  = if ($Version) { [Uri]::EscapeDataString($Version.Trim()) } else { "unknown" }
    "pkg:generic/$ns/$comp@$ver"
}

function Find-MainExecutable {
    param([string]$InstallLocation, [string]$UninstallString)
    # Versuch 1: InstallLocation durchsuchen / Attempt 1: search InstallLocation
    if ($InstallLocation -and (Test-Path $InstallLocation -ErrorAction SilentlyContinue)) {
        $exes = Get-ChildItem -Path $InstallLocation -Filter "*.exe" -Recurse -Depth 1 -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '(?i)(unins|setup|update|crash|helper)' } |
                Sort-Object Length -Descending | Select-Object -First 1
        if ($exes) { return $exes.FullName }
    }
    # Versuch 2: Aus UninstallString extrahieren / Attempt 2: extract from UninstallString
    if ($UninstallString) {
        $match = [regex]::Match($UninstallString, '(?i)([a-z]:\\[^"]+\.exe)')
        if ($match.Success -and (Test-Path $match.Value -ErrorAction SilentlyContinue)) {
            $dir = Split-Path $match.Value -Parent
            $exes = Get-ChildItem -Path $dir -Filter "*.exe" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -notmatch '(?i)(unins|setup|update)' } |
                    Sort-Object Length -Descending | Select-Object -First 1
            if ($exes) { return $exes.FullName }
        }
    }
    return $null
}

function New-CdxLicense {
    param([string]$SpdxId, [string]$Acknowledgement = "concluded")
    if ($SpdxId -like "LicenseRef-*" -or $SpdxId -eq "NOASSERTION") {
        return @{
            license = @{ name = $SpdxId }
            acknowledgement = $Acknowledgement
        }
    }
    return @{
        expression      = $SpdxId
        acknowledgement = $Acknowledgement
    }
}

function New-CdxComponent {
    param(
        [string]$Type,
        [string]$BomRef,
        [string]$Name,
        [string]$Version,
        [string]$SupplierName,
        [string]$SupplierUrl,
        [string]$Description,
        [string]$Purl,
        [string]$License,
        [string]$Filename,
        [string]$HashValue,
        [string]$Executable = "executable",
        [string]$Archive = "no archive",
        [string]$Structured = "structured",
        [hashtable[]]$ExtraProperties
    )

    $comp = [ordered]@{
        type      = $Type
        "bom-ref" = $BomRef
        name      = $Name
        version   = if ($Version) { $Version } else { "unknown" }
    }

    # Lieferant / Supplier
    $supplier = @{ name = if ($SupplierName) { $SupplierName } else { "unknown" } }
    if ($SupplierUrl) { $supplier["url"] = @($SupplierUrl) }
    $comp["supplier"] = $supplier

    # Beschreibung / Description
    if ($Description) { $comp["description"] = $Description }

    # Paket-URL / Package URL (PURL)
    if ($Purl) { $comp["purl"] = $Purl }

    # Lizenzen / Licenses (BSI TR-03183-2: SHALL)
    $licId = if ($License) { $License } else { "NOASSERTION" }
    $comp["licenses"] = @( (New-CdxLicense -SpdxId $licId) )

    # Hashes - SHA-512 (BSI TR-03183-2: SHALL / Pflichtfeld / mandatory)
    if ($HashValue) {
        $comp["hashes"] = @(@{ alg = "SHA-512"; content = $HashValue })
    }

    # Eigenschaften: BSI TR-03183-2 Pflichtfelder / Properties: BSI TR-03183-2 mandatory fields
    $props = [System.Collections.ArrayList]::new()
    [void]$props.Add(@{ name = "bsi:filename";   value = if ($Filename) { $Filename } else { "NOASSERTION" } })
    [void]$props.Add(@{ name = "bsi:executable"; value = $Executable })
    [void]$props.Add(@{ name = "bsi:archive";    value = $Archive })
    [void]$props.Add(@{ name = "bsi:structured"; value = $Structured })

    if ($ExtraProperties) {
        foreach ($p in $ExtraProperties) { [void]$props.Add($p) }
    }
    $comp["properties"] = @($props.ToArray())

    return $comp
}

# =============================================================================
#  BANNER / BANNER
# =============================================================================

$banner = @"

  ============================================================
   SCHUNK Windows SBOM Generator
   CRA / BSI TR-03183-2 v2.1.0 konform -/- compliant
   CycloneDX 1.6 (ECMA-424)
  ============================================================

"@
Write-Host $banner -ForegroundColor Cyan

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# =============================================================================
#  1) WINDOWS OS-INFORMATIONEN / OS INFORMATION
# =============================================================================

Write-Host "[1/7] Betriebssystem-Informationen... -/- Operating system information..." -ForegroundColor Yellow

$osInfo   = Get-CimInstance Win32_OperatingSystem
$csInfo   = Get-CimInstance Win32_ComputerSystem
$biosInfo = Get-CimInstance Win32_BIOS

$osData = [ordered]@{
    Hostname       = $env:COMPUTERNAME
    OSName         = $osInfo.Caption
    OSVersion      = $osInfo.Version
    BuildNumber    = $osInfo.BuildNumber
    OSArchitecture = $osInfo.OSArchitecture
    InstallDate    = $osInfo.InstallDate.ToString("yyyy-MM-dd")
    LastBoot       = $osInfo.LastBootUpTime.ToString("yyyy-MM-ddTHH:mm:ss")
    Manufacturer   = $csInfo.Manufacturer
    Model          = $csInfo.Model
    BIOSVersion    = $biosInfo.SMBIOSBIOSVersion
    SerialNumber   = $biosInfo.SerialNumber
    Domain         = $csInfo.Domain
    TotalRAM_GB    = [math]::Round($csInfo.TotalPhysicalMemory / 1GB, 1)
}

try {
    $ntVer = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
    if ($ntVer.UBR) { $osData["FullBuild"] = "$($osInfo.BuildNumber).$($ntVer.UBR)" }
    if ($ntVer.DisplayVersion) { $osData["DisplayVersion"] = $ntVer.DisplayVersion }
    if ($ntVer.EditionID) { $osData["EditionID"] = $ntVer.EditionID }
    if ($ntVer.ProductName) { $osData["ProductName"] = $ntVer.ProductName }
} catch {}

$fullBuild = if ($osData.Contains("FullBuild")) { $osData["FullBuild"] } else { $osData.OSVersion }

# =============================================================================
#  2) INSTALLIERTE UPDATES / PATCHES / INSTALLED UPDATES / PATCHES
# =============================================================================

Write-Host "[2/7] Updates und Patches... -/- Updates and patches..." -ForegroundColor Yellow

$hotfixes = @()
try {
    $hfRaw = Get-HotFix -ErrorAction SilentlyContinue |
        Sort-Object -Property InstalledOn -Descending -ErrorAction SilentlyContinue |
        Select-Object HotFixID, Description, InstalledOn, InstalledBy
    if ($hfRaw) { $hotfixes = @($hfRaw) }
} catch {
    try {
        $hfRaw = Get-CimInstance Win32_QuickFixEngineering -ErrorAction SilentlyContinue |
            Sort-Object -Property InstalledOn -Descending -ErrorAction SilentlyContinue |
            Select-Object HotFixID, Description, InstalledOn, InstalledBy
        if ($hfRaw) { $hotfixes = @($hfRaw) }
    } catch { Write-Warning "Updates nicht erfassbar -/- Updates not collectible: $_" }
}

Write-Host "   $($hotfixes.Count) Updates gefunden -/- $($hotfixes.Count) updates found" -ForegroundColor DarkGray

# =============================================================================
#  3) INSTALLIERTE ANWENDUNGEN / INSTALLED APPLICATIONS (Registry)
# =============================================================================

Write-Host "[3/7] Anwendungen aus Registry... -/- Applications from registry..." -ForegroundColor Yellow

$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
if ($IncludeUserApps) {
    $registryPaths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
}

$installedApps = [System.Collections.ArrayList]::new()
foreach ($regPath in $registryPaths) {
    try {
        $rawItems = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
        if (-not $rawItems) { continue }
        foreach ($ri in $rawItems) {
            $dn = $null
            try { $dn = $ri.DisplayName } catch {}
            if (-not $dn -or $dn.Trim() -eq "") { continue }
            $sysComp = $null
            try { $sysComp = $ri.SystemComponent } catch {}
            if ($sysComp -eq 1) { continue }

            $src = "HKLM-x64"
            if ($regPath -like "HKCU:*") { $src = "HKCU" }
            elseif ($regPath -like "*Wow6432Node*") { $src = "HKLM-x86" }

            [void]$installedApps.Add([PSCustomObject]@{
                Name            = $dn
                Version         = $(try { $ri.DisplayVersion } catch { $null })
                Publisher       = $(try { $ri.Publisher } catch { $null })
                InstallDate     = $(try { $ri.InstallDate } catch { $null })
                InstallLocation = $(try { $ri.InstallLocation } catch { $null })
                UninstallString = $(try { $ri.UninstallString } catch { $null })
                URLInfoAbout    = $(try { $ri.URLInfoAbout } catch { $null })
                Source          = $src
            })
        }
    } catch {
        Write-Warning "Registry-Pfad nicht lesbar -/- Registry path not readable (${regPath}): ${_}"
    }
}

# Duplikate entfernen / Remove duplicates
$seen = @{}
$uniqueApps = [System.Collections.ArrayList]::new()
foreach ($a in $installedApps) {
    $key = "$($a.Name)|$($a.Version)"
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = $true
    [void]$uniqueApps.Add($a)
}
$installedApps = @($uniqueApps | Sort-Object Name)

Write-Host "   $($installedApps.Count) Anwendungen gefunden -/- $($installedApps.Count) applications found" -ForegroundColor DarkGray

# =============================================================================
#  4) WINDOWS STORE APPS / STORE-ANWENDUNGEN (AppX)
# =============================================================================

$storeApps = @()
if ($IncludeStoreApps) {
    Write-Host "[4/7] Store-Apps (AppX)... -/- Store apps (AppX)..." -ForegroundColor Yellow
    try {
        $storeApps = @(Get-AppxPackage -ErrorAction SilentlyContinue |
            Where-Object { $_.IsFramework -eq $false -and $_.SignatureKind -ne "System" } |
            Select-Object Name, @{N='Version';E={$_.Version.ToString()}}, Publisher, PackageFullName, InstallLocation |
            Sort-Object Name)
    } catch { Write-Warning "AppX nicht verfuegbar -/- AppX not available: $_" }
    Write-Host "   $($storeApps.Count) Store-Apps gefunden -/- $($storeApps.Count) store apps found" -ForegroundColor DarkGray
} else {
    Write-Host "[4/7] Store-Apps uebersprungen (-IncludeStoreApps) -/- Store apps skipped (-IncludeStoreApps)" -ForegroundColor DarkGray
}

# =============================================================================
#  5) WINDOWS FEATURES / WINDOWS-FUNKTIONEN
# =============================================================================

$winFeatures = @()
if ($IncludeFeatures) {
    Write-Host "[5/7] Windows Features... -/- Windows features..." -ForegroundColor Yellow
    try {
        $winFeatures = @(Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq "Enabled" } |
            Select-Object FeatureName, State |
            Sort-Object FeatureName)
    } catch {
        try {
            $winFeatures = @(Get-CimInstance Win32_OptionalFeature -ErrorAction SilentlyContinue |
                Where-Object { $_.InstallState -eq 1 } |
                Select-Object @{N='FeatureName';E={$_.Name}}, @{N='State';E={"Enabled"}} |
                Sort-Object FeatureName)
        } catch { Write-Warning "Windows Features nicht erfassbar -/- Windows features not collectible: $_" }
    }
    Write-Host "   $($winFeatures.Count) Features aktiv -/- $($winFeatures.Count) features enabled" -ForegroundColor DarkGray
} else {
    Write-Host "[5/7] Windows Features uebersprungen (-IncludeFeatures) -/- Windows features skipped (-IncludeFeatures)" -ForegroundColor DarkGray
}

# =============================================================================
#  6) TREIBER / DRIVERS
# =============================================================================

$drivers = @()
if ($IncludeDrivers) {
    Write-Host "[6/7] Treiber... -/- Drivers..." -ForegroundColor Yellow
    try {
        $drivers = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
            Where-Object { $_.DriverVersion -and $_.DeviceName } |
            Select-Object DeviceName, DriverVersion, Manufacturer, DriverProviderName,
                          @{N='DriverDate';E={ if ($_.DriverDate) { $_.DriverDate.ToString("yyyy-MM-dd") } else { "" } }} |
            Sort-Object DeviceName -Unique)
    } catch { Write-Warning "Treiber nicht erfassbar -/- Drivers not collectible: $_" }
    Write-Host "   $($drivers.Count) Treiber gefunden -/- $($drivers.Count) drivers found" -ForegroundColor DarkGray
} else {
    Write-Host "[6/7] Treiber uebersprungen (-IncludeDrivers) -/- Drivers skipped (-IncludeDrivers)" -ForegroundColor DarkGray
}

# =============================================================================
#  7) CYCLONEDX 1.6 SBOM AUFBAUEN / BUILD CYCLONEDX 1.6 SBOM
# =============================================================================

Write-Host "[7/7] Erzeuge CycloneDX 1.6 SBOM... -/- Generating CycloneDX 1.6 SBOM..." -ForegroundColor Yellow

$timestamp = Get-Timestamp
$serialNum = "urn:uuid:$(New-Uuid)"
$hostname  = $env:COMPUTERNAME

# --- Metadaten / Metadata ---
$metadata = [ordered]@{
    timestamp = $timestamp
    tools = @{
        components = @([ordered]@{
            type      = "application"
            name      = "SCHUNK-WindowsSBOM"
            version   = $Script:ToolVersion
            supplier  = @{ name = $CompanyInfo.Name; url = @($CompanyInfo.URL) }
        })
    }
    component = [ordered]@{
        type        = "device"
        name        = "$hostname - $($osData.OSName)"
        version     = $fullBuild
        description = "Windows-Installation auf $hostname ($($osData.Manufacturer) $($osData.Model))"
        supplier    = @{ name = "Microsoft Corporation"; url = @("https://www.microsoft.com") }
    }
    manufacture = [ordered]@{
        name    = $CompanyInfo.Name
        url     = @($CompanyInfo.URL)
        contact = @(@{
            name  = $CompanyInfo.Name
            email = $CompanyInfo.Email
            phone = $CompanyInfo.Phone
        })
    }
    supplier = [ordered]@{
        name    = $CompanyInfo.Name
        url     = @($CompanyInfo.URL)
        contact = @(@{
            name  = $CompanyInfo.Name
            email = $CompanyInfo.Email
            phone = $CompanyInfo.Phone
        })
    }
}

# --- Komponenten sammeln / Collect components ---
$components = [System.Collections.ArrayList]::new()
$allRefs    = [System.Collections.ArrayList]::new()

# -- OS-Komponente / OS component --
[void]$components.Add((New-CdxComponent `
    -Type "operating-system" `
    -BomRef "os-windows" `
    -Name $osData.OSName `
    -Version $fullBuild `
    -SupplierName "Microsoft Corporation" `
    -SupplierUrl "https://www.microsoft.com" `
    -Description "Betriebssystem Build $($osData.BuildNumber), $($osData.OSArchitecture)" `
    -Purl "pkg:generic/microsoft/$([Uri]::EscapeDataString($osData.OSName))@$fullBuild" `
    -License "LicenseRef-Proprietary-Microsoft" `
    -Filename "ntoskrnl.exe" `
    -Executable "executable" `
    -Structured "structured" `
    -ExtraProperties @(
        @{ name = "os:edition";       value = $(if ($osData.Contains("EditionID")) { $osData["EditionID"] } else { "N/A" }) }
        @{ name = "os:displayVer";    value = $(if ($osData.Contains("DisplayVersion")) { $osData["DisplayVersion"] } else { "N/A" }) }
        @{ name = "os:architecture";  value = $osData.OSArchitecture }
        @{ name = "os:installDate";   value = $osData.InstallDate }
        @{ name = "hw:manufacturer";  value = $osData.Manufacturer }
        @{ name = "hw:model";         value = $osData.Model }
        @{ name = "hw:biosVersion";   value = $osData.BIOSVersion }
        @{ name = "hw:serialNumber";  value = $osData.SerialNumber }
        @{ name = "hw:domain";        value = $osData.Domain }
        @{ name = "hw:totalRAM_GB";   value = $osData.TotalRAM_GB.ToString() }
    )
))

# -- Patches / Patches --
$patchRefs = @()
$pi = 0
foreach ($hf in $hotfixes) {
    $pi++
    $ref = "patch-$pi"
    $patchRefs += $ref
    $dt = ""
    if ($hf.InstalledOn) { try { $dt = ([DateTime]$hf.InstalledOn).ToString("yyyy-MM-dd") } catch { $dt = "$($hf.InstalledOn)" } }
    $descText = if ($hf.Description) { $hf.Description } else { "Update" }
    $byText   = if ($hf.InstalledBy) { $hf.InstalledBy } else { "N/A" }

    [void]$components.Add((New-CdxComponent `
        -Type "firmware" `
        -BomRef $ref `
        -Name $hf.HotFixID `
        -Version $dt `
        -SupplierName "Microsoft Corporation" `
        -SupplierUrl "https://www.microsoft.com" `
        -Description "$descText - installiert $dt von $byText" `
        -Purl "pkg:generic/microsoft/$($hf.HotFixID)@$dt" `
        -License "LicenseRef-Proprietary-Microsoft" `
        -Filename "$($hf.HotFixID).msu" `
        -Executable "non-executable" `
        -Archive "archive" `
        -Structured "structured" `
        -ExtraProperties @(
            @{ name = "patch:type"; value = $descText }
            @{ name = "patch:installedBy"; value = $byText }
        )
    ))
}

# -- Registry-Anwendungen / Registry apps --
Write-Host "   Hashing und Lizenz-Zuordnung fuer $($installedApps.Count) Anwendungen... -/- Hashing and license mapping for $($installedApps.Count) applications..." -ForegroundColor DarkGray
$appRefs = @()
$ai = 0
foreach ($app in $installedApps) {
    $ai++
    $ref = "app-$ai"
    $appRefs += $ref

    $version   = if ($app.Version) { $app.Version } else { "unknown" }
    $publisher = if ($app.Publisher) { $app.Publisher } else { "unknown" }
    $license   = Resolve-License -AppName $app.Name -Publisher $publisher

    # Dateiname und Hash ermitteln / Determine filename and hash
    $mainExe  = Find-MainExecutable -InstallLocation $app.InstallLocation -UninstallString $app.UninstallString
    $filename = if ($mainExe) { Split-Path $mainExe -Leaf } else { $null }
    $hash     = if ($mainExe) { Get-SHA512Safe -Path $mainExe } else { $null }

    $isExe = if ($filename -and $filename -match '\.exe$') { "executable" } else { "non-executable" }
    $supplierUrl = if ($app.URLInfoAbout) { $app.URLInfoAbout } else { $null }

    $extras = @( @{ name = "app:registrySource"; value = $app.Source } )
    if ($app.InstallDate) { $extras += @{ name = "app:installDate"; value = $app.InstallDate } }

    [void]$components.Add((New-CdxComponent `
        -Type "application" `
        -BomRef $ref `
        -Name $app.Name `
        -Version $version `
        -SupplierName $publisher `
        -SupplierUrl $supplierUrl `
        -Purl (ConvertTo-Purl -Publisher $publisher -Name $app.Name -Version $version) `
        -License $license `
        -Filename $filename `
        -HashValue $hash `
        -Executable $isExe `
        -Archive "no archive" `
        -Structured "structured" `
        -ExtraProperties $extras
    ))
}

# -- Store-Anwendungen / Store apps --
$storeRefs = @()
$si = 0
foreach ($sa in $storeApps) {
    $si++
    $ref = "store-$si"
    $storeRefs += $ref

    $pub = $sa.Publisher
    if ($pub -match 'CN=([^,]+)') { $pub = $Matches[1] }

    [void]$components.Add((New-CdxComponent `
        -Type "application" `
        -BomRef $ref `
        -Name $sa.Name `
        -Version $sa.Version `
        -SupplierName $pub `
        -Purl "pkg:generic/microsoft-store/$([Uri]::EscapeDataString($sa.Name))@$($sa.Version)" `
        -License "NOASSERTION" `
        -Filename "$($sa.Name).appx" `
        -Executable "executable" `
        -Archive "archive" `
        -Structured "structured"
    ))
}

# -- Windows-Funktionen / Windows features --
$featRefs = @()
$fi = 0
foreach ($feat in $winFeatures) {
    $fi++
    $ref = "feature-$fi"
    $featRefs += $ref

    [void]$components.Add((New-CdxComponent `
        -Type "framework" `
        -BomRef $ref `
        -Name $feat.FeatureName `
        -Version $fullBuild `
        -SupplierName "Microsoft Corporation" `
        -SupplierUrl "https://www.microsoft.com" `
        -License "LicenseRef-Proprietary-Microsoft" `
        -Filename "NOASSERTION" `
        -Executable "non-executable" `
        -Archive "no archive" `
        -Structured "structured"
    ))
}

# -- Treiber / Drivers --
$drvRefs = @()
$di = 0
foreach ($drv in $drivers) {
    $di++
    $ref = "driver-$di"
    $drvRefs += $ref

    $mfr = if ($drv.Manufacturer) { $drv.Manufacturer } else { if ($drv.DriverProviderName) { $drv.DriverProviderName } else { "unknown" } }

    [void]$components.Add((New-CdxComponent `
        -Type "device-driver" `
        -BomRef $ref `
        -Name $drv.DeviceName `
        -Version $drv.DriverVersion `
        -SupplierName $mfr `
        -License "NOASSERTION" `
        -Filename "NOASSERTION" `
        -Executable "executable" `
        -Archive "no archive" `
        -Structured "structured" `
        -ExtraProperties @(
            @{ name = "driver:date"; value = if ($drv.DriverDate) { $drv.DriverDate } else { "N/A" } }
            @{ name = "driver:provider"; value = if ($drv.DriverProviderName) { $drv.DriverProviderName } else { "N/A" } }
        )
    ))
}

# --- Abhaengigkeiten / Dependencies ---
$dependencies = @(
    [ordered]@{
        ref       = "os-windows"
        dependsOn = @($patchRefs + $featRefs + $drvRefs)
    }
)

# --- SBOM-Dokument / SBOM document ---
$sbom = [ordered]@{
    "`$schema"   = "http://cyclonedx.org/schema/bom-1.6.schema.json"
    bomFormat    = "CycloneDX"
    specVersion  = "1.6"
    serialNumber = $serialNum
    version      = 1
    metadata     = $metadata
    components   = @($components.ToArray())
    dependencies = $dependencies
}

# --- Dateien schreiben / Write files ---
if (-not (Test-Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null }

$dateSuffix   = Get-Date -Format "yyyyMMdd-HHmmss"
$cdxFile      = Join-Path $OutputDir "$hostname-sbom-$dateSuffix.cdx.json"
$readableFile = Join-Path $OutputDir "$hostname-sbom-$dateSuffix.txt"

$jsonContent = $sbom | ConvertTo-Json -Depth 30
$utf8NoBom   = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($cdxFile, $jsonContent, $utf8NoBom)

# =============================================================================
#  HTML-REPORT / HTML REPORT (Tabellenform, sortierbar, durchsuchbar / tabular, sortable, searchable)
# =============================================================================

$sw.Stop()
$htmlFile = Join-Path $OutputDir "$hostname-sbom-$dateSuffix.html"

function HtmlEnc([string]$s) { if ($s) { [System.Net.WebUtility]::HtmlEncode($s) } else { "" } }

$h = [System.Text.StringBuilder]::new(256000)
[void]$h.Append(@"
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>SBOM $hostname - $(Get-Date -Format 'yyyy-MM-dd')</title>
<link rel="icon" type="image/png" href="../assets/logos/SCHUNK_Signet.png">
<style>
:root{
  --schunk-primary:#003D6A;--schunk-accent:#009EE0;--schunk-cta:#F26B43;
  --bg:#F0F2F5;--card:#fff;--border:#E3E3E3;--accent:#003D6A;--accent2:#009263;
  --text:#212529;--muted:#44546A;--warn:#D8BA22;
  --header-bg:linear-gradient(135deg,#003D6A 0%,#002847 100%);
  --row-hover:#f0f8fc;--th-bg:#003D6A;--th-text:#fff;
  --font:"Segoe UI",system-ui,-apple-system,Arial,sans-serif;
}
html.dark{
  --bg:#0B1E2E;--card:#12324A;--border:#1E4466;--accent:#009EE0;--accent2:#00B37A;
  --text:#F0F4F8;--muted:#A4B8C8;--header-bg:linear-gradient(135deg,#0B1E2E 0%,#061018 100%);
  --row-hover:#163A55;--th-bg:#009EE0;--th-text:#fff;
}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:var(--font);background:var(--bg);color:var(--text);line-height:1.5;padding:0 0 1.5rem;transition:background .25s,color .25s}
.site-header{background:var(--header-bg);color:#fff;padding:.85rem 1.5rem 1rem;box-shadow:0 2px 12px rgba(0,0,0,.2);display:flex;flex-wrap:wrap;align-items:center;gap:1rem;margin-bottom:1.2rem}
.header-brand{display:flex;align-items:center;gap:1rem;flex:1;min-width:220px}
.header-brand img.logo-full{height:40px;width:auto}
.header-brand h1{font-size:1.35rem;font-weight:700;line-height:1.2}
.header-sub{font-size:.78rem;opacity:.9;margin-top:.15rem}
.content{padding:0 1.5rem}
.top-controls{display:flex;flex-wrap:wrap;gap:.55rem;margin-left:auto}
.control-pill{display:flex;align-items:center;gap:8px;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);border-radius:12px;padding:5px 10px;font-size:.72rem;font-weight:600}
.control-label{opacity:.85}
.toggle-btn{display:flex;align-items:center;gap:8px;background:transparent;border:none;cursor:pointer;padding:0;color:#fff}
.toggle-track{width:46px;height:26px;background:rgba(0,0,0,.25);border-radius:13px;position:relative;border:1px solid rgba(255,255,255,.25)}
.toggle-knob{position:absolute;top:2px;left:2px;width:20px;height:20px;background:#fff;border-radius:50%;transition:transform .25s cubic-bezier(.4,0,.2,1);box-shadow:0 1px 4px rgba(0,0,0,.25)}
body.en .lang-track .toggle-knob,html.dark .theme-track .toggle-knob{transform:translateX(20px)}
.lang-opt,.theme-opt{opacity:.45;font-weight:700;user-select:none}
.lang-opt.active,.theme-opt.active{opacity:1}
h2{font-size:1.15rem;margin:1.8rem 0 .6rem;padding-bottom:.3rem;border-bottom:2px solid var(--schunk-accent);color:var(--accent)}
.meta{color:var(--muted);font-size:.85rem;margin-bottom:1.2rem}
.stats{display:flex;gap:.8rem;flex-wrap:wrap;margin:1rem 0}
.stat{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:.7rem 1.1rem;min-width:130px;text-align:center;box-shadow:0 1px 4px rgba(0,61,106,.06)}
.stat b{display:block;font-size:1.5rem;color:var(--schunk-accent)}
html:not(.dark) .stat b{color:var(--schunk-primary)}
.stat span{font-size:.78rem;color:var(--muted)}
.badge{display:inline-block;padding:1px 7px;border-radius:4px;font-size:.75rem;font-weight:600}
.badge-ok{background:rgba(0,146,99,.15);color:#009263}
.badge-warn{background:rgba(216,186,34,.2);color:#8a7010}
html.dark .badge-warn{color:#E8C547}
.badge-na{background:rgba(68,84,106,.15);color:var(--muted)}
table{width:100%;border-collapse:collapse;background:var(--card);border:1px solid var(--border);border-radius:6px;overflow:hidden;margin-bottom:.5rem;font-size:.82rem}
th{background:var(--th-bg);color:var(--th-text);position:sticky;top:0;padding:6px 8px;text-align:left;cursor:pointer;user-select:none;white-space:nowrap}
th:hover{filter:brightness(1.08)}
th::after{content:' \2195';opacity:.6;font-size:.7rem}
td{padding:5px 8px;border-top:1px solid var(--border);word-break:break-word}
tr:hover{background:var(--row-hover)}
.os-tbl td:first-child{font-weight:600;width:180px;color:var(--muted)}
input[type=search]{width:100%;padding:6px 10px;border:1px solid var(--border);border-radius:6px;margin-bottom:6px;font-size:.85rem;background:var(--card);color:var(--text)}
.section{margin-bottom:2rem}
.hash{font-family:Consolas,monospace;font-size:.7rem;word-break:break-all;max-width:280px;display:inline-block}
footer{margin-top:2rem;padding:1rem 1.5rem 0;border-top:1px solid var(--border);font-size:.78rem;color:var(--muted)}
[data-en]{display:none}
body.en [data-de]{display:none}
body.en [data-en]{display:inline}
body.en h2[data-de]{display:none}
body.en h2[data-en]{display:block}
h2[data-en]{display:none}
@media print{body{padding:0;font-size:9pt}th{background:#003D6A!important;color:#fff!important}input,.meta a,.top-controls{display:none}.stat{border:1px solid #ccc}html.dark{--bg:#fff;--card:#fff;--text:#000}}
</style>
</head>
<body>
<header class="site-header">
<div class="header-brand">
<img class="logo-full" src="../assets/logos/SCHUNK_Logo_Dark.svg" alt="SCHUNK">
<div>
<h1><span data-de>Windows SBOM</span><span data-en>Windows SBOM</span></h1>
<div class="header-sub">CRA / BSI TR-03183-2 v2.1.0 &middot; CycloneDX 1.6</div>
</div>
</div>
<div class="top-controls">
<div class="control-pill">
<span class="control-label"><span data-de>Design</span><span data-en>Theme</span></span>
<button class="toggle-btn" type="button" onclick="toggleTheme()" aria-label="Dark Mode">
<span class="theme-opt active" id="themeLight">&#9728;</span>
<span class="toggle-track theme-track"><span class="toggle-knob"></span></span>
<span class="theme-opt" id="themeDark">&#9790;</span>
</button>
</div>
<div class="control-pill">
<span class="control-label"><span data-de>Sprache</span><span data-en>Language</span></span>
<button class="toggle-btn" type="button" onclick="toggleLang()" aria-label="Sprache / Language">
<span class="lang-opt active" id="flagDe">DE</span>
<span class="toggle-track lang-track"><span class="toggle-knob"></span></span>
<span class="lang-opt" id="flagEn">EN</span>
</button>
</div>
</div>
</header>
<div class="content">
<div class="meta">
<span data-de>Erstellt:</span><span data-en>Created:</span> $timestamp &middot; Host: <b>$hostname</b><br>
<span data-de>Organisation:</span><span data-en>Organization:</span> <b>$(HtmlEnc $CompanyInfo.Name)</b> &middot;
$(HtmlEnc $CompanyInfo.Street), $(HtmlEnc $CompanyInfo.City) &middot;
<a href="$(HtmlEnc $CompanyInfo.URL)" style="color:var(--schunk-accent)">$(HtmlEnc $CompanyInfo.URL)</a>
</div>

<div class="stats">
<div class="stat"><b>$($components.Count)</b><span data-de>Komponenten</span><span data-en>Components</span></div>
<div class="stat"><b>$($hotfixes.Count)</b><span>Patches</span></div>
<div class="stat"><b>$($installedApps.Count)</b><span data-de>Anwendungen</span><span data-en>Applications</span></div>
<div class="stat"><b>$($storeApps.Count)</b><span>Store-Apps</span></div>
<div class="stat"><b>$($winFeatures.Count)</b><span>Features</span></div>
<div class="stat"><b>$($drivers.Count)</b><span data-de>Treiber</span><span data-en>Drivers</span></div>
<div class="stat"><b>$([math]::Round($sw.Elapsed.TotalSeconds,1))s</b><span data-de>Laufzeit</span><span data-en>Runtime</span></div>
</div>
"@)

# --- OS-Info Tabelle / OS info table ---
[void]$h.Append('<div class="section"><h2 data-de>Betriebssystem</h2><h2 data-en>Operating System</h2><table class="os-tbl">')
foreach ($key in $osData.Keys) {
    [void]$h.Append("<tr><td>$(HtmlEnc $key)</td><td>$(HtmlEnc "$($osData[$key])")</td></tr>")
}
[void]$h.Append('</table></div>')

# --- Patches ---
[void]$h.Append('<div class="section"><h2 data-de>Updates / Patches</h2><h2 data-en>Updates / Patches</h2><table><thead><tr><th><span data-de>KB-Nummer</span><span data-en>KB Number</span></th><th><span data-de>Typ</span><span data-en>Type</span></th><th><span data-de>Datum</span><span data-en>Date</span></th><th><span data-de>Installiert von</span><span data-en>Installed by</span></th></tr></thead><tbody>')
foreach ($hf in $hotfixes) {
    $dt = ""; if ($hf.InstalledOn) { try { $dt = ([DateTime]$hf.InstalledOn).ToString("yyyy-MM-dd") } catch { $dt = "?" } }
    $desc = if ($hf.Description) { $hf.Description } else { "Update" }
    $by = if ($hf.InstalledBy) { $hf.InstalledBy } else { "?" }
    [void]$h.Append("<tr><td><b>$(HtmlEnc $hf.HotFixID)</b></td><td>$(HtmlEnc $desc)</td><td>$dt</td><td>$(HtmlEnc $by)</td></tr>")
}
[void]$h.Append('</tbody></table></div>')

# --- Anwendungen / Applications ---
[void]$h.Append('<div class="section"><h2 data-de>Anwendungen (Registry)</h2><h2 data-en>Applications (Registry)</h2>')
[void]$h.Append('<input type="search" id="appSearch" placeholder="Search / Suchen..." onkeyup="filterTable(this,''appTbl'')">')
[void]$h.Append('<table id="appTbl"><thead><tr><th onclick="sortTbl(''appTbl'',0)">Name</th><th onclick="sortTbl(''appTbl'',1)">Version</th><th onclick="sortTbl(''appTbl'',2)"><span data-de>Herausgeber</span><span data-en>Publisher</span></th><th onclick="sortTbl(''appTbl'',3)"><span data-de>Lizenz</span><span data-en>License</span></th><th onclick="sortTbl(''appTbl'',4)">Hash</th><th onclick="sortTbl(''appTbl'',5)"><span data-de>Datei</span><span data-en>File</span></th><th><span data-de>Quelle</span><span data-en>Source</span></th></tr></thead><tbody>')
foreach ($app in $installedApps) {
    $version   = if ($app.Version) { $app.Version } else { "?" }
    $publisher = if ($app.Publisher) { $app.Publisher } else { "?" }
    $lic = Resolve-License -AppName $app.Name -Publisher $publisher
    $licBadge = if ($lic -eq "NOASSERTION") { '<span class="badge badge-na">NOASSERTION</span>' }
                elseif ($lic -like "LicenseRef-*") { "<span class='badge badge-warn'>$(HtmlEnc $lic)</span>" }
                else { "<span class='badge badge-ok'>$(HtmlEnc $lic)</span>" }
    $mainExe  = Find-MainExecutable -InstallLocation $app.InstallLocation -UninstallString $app.UninstallString
    $filename = if ($mainExe) { Split-Path $mainExe -Leaf } else { "-" }
    $hashDisp = if ($mainExe) { $hv = Get-SHA512Safe -Path $mainExe; if ($hv) { "<span class='hash'>$($hv.Substring(0,24))...</span>" } else { "-" } } else { "-" }
    [void]$h.Append("<tr><td>$(HtmlEnc $app.Name)</td><td>$(HtmlEnc $version)</td><td>$(HtmlEnc $publisher)</td><td>$licBadge</td><td>$hashDisp</td><td>$(HtmlEnc $filename)</td><td>$($app.Source)</td></tr>")
}
[void]$h.Append('</tbody></table></div>')

# --- Store Apps ---
if ($storeApps.Count -gt 0) {
    [void]$h.Append('<div class="section"><h2 data-de>Store-Apps (AppX)</h2><h2 data-en>Store Apps (AppX)</h2>')
    [void]$h.Append('<input type="search" placeholder="Search / Suchen..." onkeyup="filterTable(this,''storeTbl'')">')
    [void]$h.Append('<table id="storeTbl"><thead><tr><th onclick="sortTbl(''storeTbl'',0)">Name</th><th onclick="sortTbl(''storeTbl'',1)">Version</th><th onclick="sortTbl(''storeTbl'',2)">Publisher</th></tr></thead><tbody>')
    foreach ($sa in $storeApps) {
        $pub = $sa.Publisher; if ($pub -match 'CN=([^,]+)') { $pub = $Matches[1] }
        [void]$h.Append("<tr><td>$(HtmlEnc $sa.Name)</td><td>$($sa.Version)</td><td>$(HtmlEnc $pub)</td></tr>")
    }
    [void]$h.Append('</tbody></table></div>')
}

# --- Windows Features ---
if ($winFeatures.Count -gt 0) {
    [void]$h.Append('<div class="section"><h2>Windows Features</h2><table><thead><tr><th>Feature</th><th><span data-de>Status</span><span data-en>Status</span></th></tr></thead><tbody>')
    foreach ($f in $winFeatures) {
        [void]$h.Append("<tr><td>$(HtmlEnc $f.FeatureName)</td><td>Enabled</td></tr>")
    }
    [void]$h.Append('</tbody></table></div>')
}

# --- Treiber / Drivers ---
if ($drivers.Count -gt 0) {
    [void]$h.Append('<div class="section"><h2 data-de>Treiber</h2><h2 data-en>Drivers</h2>')
    [void]$h.Append('<input type="search" placeholder="Search / Suchen..." onkeyup="filterTable(this,''drvTbl'')">')
    [void]$h.Append('<table id="drvTbl"><thead><tr><th onclick="sortTbl(''drvTbl'',0)"><span data-de>Geraet</span><span data-en>Device</span></th><th onclick="sortTbl(''drvTbl'',1)">Version</th><th onclick="sortTbl(''drvTbl'',2)"><span data-de>Hersteller</span><span data-en>Manufacturer</span></th><th><span data-de>Datum</span><span data-en>Date</span></th></tr></thead><tbody>')
    foreach ($d in $drivers) {
        $mf = if ($d.Manufacturer) { $d.Manufacturer } else { "?" }
        [void]$h.Append("<tr><td>$(HtmlEnc $d.DeviceName)</td><td>$($d.DriverVersion)</td><td>$(HtmlEnc $mf)</td><td>$($d.DriverDate)</td></tr>")
    }
    [void]$h.Append('</tbody></table></div>')
}

# --- Konformitaet / Compliance ---
[void]$h.Append(@"
<div class="section"><h2 data-de>BSI TR-03183-2 Konformitaet</h2><h2 data-en>BSI TR-03183-2 Compliance</h2>
<table class="os-tbl">
<tr><td>Format</td><td>CycloneDX 1.6 (ECMA-424)</td></tr>
<tr><td><span data-de>Spec-Referenz</span><span data-en>Spec Reference</span></td><td>BSI TR-03183-2 v2.1.0 (Sep 2025)</td></tr>
<tr><td>SBOM Creator</td><td>$(HtmlEnc $CompanyInfo.Name)</td></tr>
<tr><td>Timestamp</td><td>$timestamp</td></tr>
<tr><td>Component Name</td><td><span class="badge badge-ok">OK</span> <span data-de>alle Komponenten</span><span data-en>all components</span></td></tr>
<tr><td>Component Version</td><td><span class="badge badge-ok">OK</span> <span data-de>alle Komponenten</span><span data-en>all components</span></td></tr>
<tr><td>Component Creator</td><td><span class="badge badge-ok">OK</span> <span data-de>Supplier-Feld</span><span data-en>supplier field</span></td></tr>
<tr><td>Filename</td><td><span class="badge badge-ok">OK</span> <span data-de>wo ermittelbar</span><span data-en>where determinable</span></td></tr>
<tr><td>Distribution Licences</td><td><span class="badge badge-ok">OK</span> <span data-de>SPDX-ID oder NOASSERTION</span><span data-en>SPDX-ID or NOASSERTION</span></td></tr>
<tr><td>Hash (SHA-512)</td><td><span class="badge badge-ok">OK</span> <span data-de>wo EXE erreichbar</span><span data-en>where EXE reachable</span></td></tr>
<tr><td>Dependencies</td><td><span class="badge badge-ok">OK</span> <span data-de>Patches/Features/Treiber</span><span data-en>Patches/Features/Drivers</span> &rarr; OS</td></tr>
<tr><td>Executable Property</td><td><span class="badge badge-ok">OK</span> <span data-de>alle Komponenten</span><span data-en>all components</span></td></tr>
<tr><td>Archive Property</td><td><span class="badge badge-ok">OK</span> <span data-de>alle Komponenten</span><span data-en>all components</span></td></tr>
<tr><td>Structured Property</td><td><span class="badge badge-ok">OK</span> <span data-de>alle Komponenten</span><span data-en>all components</span></td></tr>
</table></div>
"@)

# --- Footer ---
[void]$h.Append(@"
<footer>
SCHUNK Windows SBOM Generator v$Script:ToolVersion &middot; $(HtmlEnc $CompanyInfo.Name) &middot;
<span data-de>Generiert</span><span data-en>Generated</span> $timestamp<br>
CycloneDX: <code>$(Split-Path $cdxFile -Leaf)</code> &middot; HTML: <code>$(Split-Path $htmlFile -Leaf)</code>
</footer>
</div>
<script>
function filterTable(input,tblId){var f=input.value.toLowerCase(),rows=document.getElementById(tblId).tBodies[0].rows;
for(var i=0;i<rows.length;i++){rows[i].style.display=rows[i].textContent.toLowerCase().indexOf(f)>-1?'':'none';}}
function sortTbl(tblId,col){var t=document.getElementById(tblId),b=t.tBodies[0],rows=Array.from(b.rows),
asc=t.dataset.sortCol==col&&t.dataset.sortAsc!='1';t.dataset.sortCol=col;t.dataset.sortAsc=asc?'1':'0';
rows.sort(function(a,b){var x=a.cells[col].textContent.trim(),y=b.cells[col].textContent.trim();
return asc?x.localeCompare(y,undefined,{numeric:true}):y.localeCompare(x,undefined,{numeric:true});});
rows.forEach(function(r){b.appendChild(r);});}
function toggleLang(){
document.body.classList.toggle('en');
var isEn=document.body.classList.contains('en');
document.getElementById('flagDe').classList.toggle('active',!isEn);
document.getElementById('flagEn').classList.toggle('active',isEn);
try{localStorage.setItem('sbom-lang',isEn?'en':'de');}catch(e){}}
function toggleTheme(){
var dark=!document.documentElement.classList.contains('dark');
document.documentElement.classList.toggle('dark',dark);
document.getElementById('themeLight').classList.toggle('active',!dark);
document.getElementById('themeDark').classList.toggle('active',dark);
try{localStorage.setItem('sbom-theme',dark?'dark':'light');}catch(e){}}
(function(){
try{var l=localStorage.getItem('sbom-lang');
if(l==='en'){document.body.classList.add('en');
document.getElementById('flagDe').classList.remove('active');
document.getElementById('flagEn').classList.add('active');}
var t=localStorage.getItem('sbom-theme');
if(t==='dark'){document.documentElement.classList.add('dark');
document.getElementById('themeLight').classList.remove('active');
document.getElementById('themeDark').classList.add('active');}}catch(e){}})();
</script>
</body></html>
"@)

[System.IO.File]::WriteAllText($htmlFile, $h.ToString(), $utf8NoBom)

# =============================================================================
#  TEXT-ZUSAMMENFASSUNG / TEXT SUMMARY (kompakt, fuer Konsole + .txt / compact, for console + .txt)
# =============================================================================

$r = [System.Text.StringBuilder]::new()
$line = "=" * 90
$sep  = "-" * 90

[void]$r.AppendLine($line)
[void]$r.AppendLine("  SCHUNK Windows SBOM - CRA / BSI TR-03183-2 v2.1.0")
[void]$r.AppendLine("  Erstellt -/- Created: $timestamp | Host: $hostname")
[void]$r.AppendLine("  Organisation -/- Organization: $($CompanyInfo.Name)")
[void]$r.AppendLine($line)

[void]$r.AppendLine("")
[void]$r.AppendLine("  STATISTIK -/- STATISTICS")
[void]$r.AppendLine($sep)
[void]$r.AppendLine("  Betriebssystem -/- Operating system : 1   ($($osData.OSName) $fullBuild)")
[void]$r.AppendLine("  Patches / Updates                   : $($hotfixes.Count)")
[void]$r.AppendLine("  Anwendungen (Registry) -/- Applications (registry) : $($installedApps.Count)")
[void]$r.AppendLine("  Store-Apps                          : $($storeApps.Count)")
[void]$r.AppendLine("  Windows Features                    : $($winFeatures.Count)")
[void]$r.AppendLine("  Treiber -/- Drivers                 : $($drivers.Count)")
[void]$r.AppendLine("  ------------------------------------")
[void]$r.AppendLine("  GESAMT KOMPONENTEN -/- TOTAL COMPONENTS : $($components.Count)")
[void]$r.AppendLine("  Laufzeit -/- Runtime                : $([math]::Round($sw.Elapsed.TotalSeconds, 1))s")

[void]$r.AppendLine("")
[void]$r.AppendLine("  DATEIEN -/- FILES")
[void]$r.AppendLine($sep)
[void]$r.AppendLine("  CycloneDX JSON  : $cdxFile")
[void]$r.AppendLine("  HTML-Report     : $htmlFile")
[void]$r.AppendLine("  Text-Datei -/- Text file : $readableFile")
[void]$r.AppendLine($line)

$reportText = $r.ToString()
[System.IO.File]::WriteAllText($readableFile, $reportText, $utf8NoBom)

Write-Host ""
Write-Host $reportText
Write-Host ""
Write-Host "FERTIG! -/- DONE!" -ForegroundColor Green
Write-Host "  CycloneDX JSON  : $cdxFile" -ForegroundColor Yellow
Write-Host "  HTML-Report     : $htmlFile" -ForegroundColor Yellow
Write-Host "  Text-Datei -/- Text file : $readableFile" -ForegroundColor Yellow
Write-Host ""
