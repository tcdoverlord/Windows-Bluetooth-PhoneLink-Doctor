# 📱 Windows Bluetooth PhoneLink Doctor

> **Diagnose • Repair • Restore Windows Bluetooth, Audio, and Microsoft Phone Link**

<p align="center">
  <img src="images/Windows_Bluetooth_PhoneLink_Doctor_Hero.png" alt="Windows Bluetooth PhoneLink Doctor" width="100%">
</p>

## Technology Cards

![Windows](https://img.shields.io/badge/Platform-Windows_10%20%7C%2011-0078D4?style=for-the-badge&logo=windows)
![PowerShell](https://img.shields.io/badge/Engine-PowerShell_5.1+-5391FE?style=for-the-badge&logo=powershell)
![Batch](https://img.shields.io/badge/Launcher-Batch-4D4D4D?style=for-the-badge)
![License](https://img.shields.io/badge/License-TCDOVERLORD_Personal_Learning_License-orange?style=for-the-badge)

---

# Overview

Windows Bluetooth PhoneLink Doctor is a Windows diagnostic and repair utility that automates many of the most common Bluetooth, audio, and Microsoft Phone Link troubleshooting steps.

Instead of manually restarting services, navigating multiple settings pages, or guessing which microphone or speakers Windows is using, the tool performs automated checks, attempts safe repairs, records diagnostic logs, and guides you through selecting the correct devices when needed.

---

# Features

- Automated Bluetooth diagnostics and repair
- Microsoft Phone Link diagnostics
- Windows audio service verification
- Simple **RUN / RESET** workflow
- Progress window during repairs
- Diagnostic log generation
- Opens the Windows Sound Control Panel (`mmsys.cpl`) for manual audio selection
- Smart restart recommendations (only when appropriate)

---

# Quick Fix

If audio still isn't working after repairs:

1. Press **Win + R**
2. Type:

```text
mmsys.cpl
```

3. Open the **Recording** tab.
4. Speak into each microphone and watch for the green activity meter.
5. Right-click the correct microphone.
6. Select **Set as Default Device**.
7. Select **Set as Default Communication Device**.
8. Click **Apply** then **OK**.

To change speakers:

1. Open the **Playback** tab.
2. Right-click the correct speakers or headset.
3. Choose **Set as Default Device**.
4. Click **Apply** then **OK**.

---

# Architecture

```mermaid
flowchart TD
A[RUN_PHONE_LINK_DOCTOR.bat] --> B[PhoneLink-Bluetooth-Doctor.ps1]
B --> C[Bluetooth Checks]
B --> D[Phone Link Checks]
B --> E[Audio Service Checks]
C --> F[Repair Engine]
D --> F
E --> F
F --> G[Progress Window]
G --> H[Logs]
H --> I[Open mmsys.cpl if needed]
```

# Execution Pipeline

```text
Launch
 ↓
Verify Administrator
 ↓
Bluetooth Checks
 ↓
Phone Link Checks
 ↓
Audio Service Checks
 ↓
Run Repairs
 ↓
Generate Logs
 ↓
Complete
```

# Project Tree

```text
Windows-Bluetooth-PhoneLink-Doctor/
├── .gitignore
├── LICENSE
├── README.md
├── RUN_PHONE_LINK_DOCTOR.bat
├── config/
├── images/
├── logs/
└── scripts/
    ├── PhoneLink-Bluetooth-Doctor.ps1
    └── PhoneLink-Progress.ps1
```

# Installation

```powershell
git clone https://github.com/tcdoverlord/Windows-Bluetooth-PhoneLink-Doctor.git
cd Windows-Bluetooth-PhoneLink-Doctor
```

# Quick Start

Double-click:

```text
RUN_PHONE_LINK_DOCTOR.bat
```

Menu options:

- **RUN** — Performs diagnostics and repairs.
- **RESET** — Clears saved audio/device selections so the next RUN starts fresh.
- **EXIT** — Closes the application.

# Logs

Diagnostic logs are written to:

```text
logs/
```

Include the latest log when reporting issues.

# Roadmap

- [x] Simplified RUN / RESET workflow
- [x] Smart restart detection
- [ ] Enhanced Bluetooth diagnostics
- [ ] Additional driver repair options
- [ ] Optional graphical interface

# Version History

## v1.1.1

- Simplified menu to RUN / RESET / EXIT
- Added smart restart recommendations
- Integrated Windows Sound Control Panel guidance
- Improved audio device recovery workflow

# License

This project is licensed under the **TCDOVERLORD Personal Learning License (TPLL) v1.0**.

See the **LICENSE** file for complete terms.

# Author

**TCDOVERLORD**

Building practical Windows utilities, automation tools, diagnostic scripts, and open-source learning projects.

# Support

When opening an issue, include:

- Windows version
- Bluetooth device
- Phone model
- Latest log from `logs/`
- Steps already attempted

## ⭐ Star History

## Star History

[![Star History Chart](https://api.star-history.com/chart?repos=tcdoverlord/SafeUSB-Eject-Windows11%2CWindows-Bluetooth-PhoneLink-Doctor/Windows-Bluetooth-PhoneLink-Doctor&type=date&legend=top-left&sealed_token=Uv2aKBy5S1VcscKkEOooMX-B0WyNB2qd4Q0ChbqP3gHMeK5sSu_VVZqZ-ZqOQoZYIeY_Cru-iEooz_LEnRdzYm3pnibyNQny8KKV-l3DHbIitCLnud-8uhqwHgLgC8-9JZYtCwqjQ0ceWnsojICZnmzJ8kvhyWrX7W9_mPmdzFCl4BIX6beFBiVIq-FA)](https://www.star-history.com/?repos=tcdoverlord%2FSafeUSB-Eject-Windows11%2CWindows-Bluetooth-PhoneLink-Doctor%2FWindows-Bluetooth-PhoneLink-Doctor&type=date&legend=top-left)

# Golden Rule

```text
Build
 ↓
Test
 ↓
Document
 ↓
git status
 ↓
git add .
 ↓
git status
 ↓
git commit
 ↓
git push
 ↓
Verify
 ↓
Release
```
