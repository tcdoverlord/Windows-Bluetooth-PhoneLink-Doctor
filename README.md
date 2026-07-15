# 📱 Windows Bluetooth PhoneLink Doctor

> **Diagnose • Repair • Restore Windows Bluetooth and Microsoft Phone Link**

<p align="center">
  <img src="images/Phone%20Link%20and%20Bluetooth%20Doctor%20diag.png" alt="Windows Bluetooth PhoneLink Doctor Architecture" width="100%">
</p>

<p align="center">

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Batch](https://img.shields.io/badge/Batch-Windows-informational?style=for-the-badge)
![Git](https://img.shields.io/badge/Git-Version_Control-F05032?style=for-the-badge&logo=git&logoColor=white)
![License](https://img.shields.io/badge/License-TCDOVERLORD-orange?style=for-the-badge)

</p>

---

# 📖 Overview

Windows Bluetooth PhoneLink Doctor is a lightweight PowerShell toolkit designed to diagnose and repair common Windows Bluetooth and Microsoft Phone Link issues.

Instead of manually restarting services, checking drivers, or navigating multiple Windows settings pages, the toolkit automates common troubleshooting tasks while providing progress feedback and logging.

---

# ✨ Features

- 🔵 Bluetooth diagnostics
- 📱 Microsoft Phone Link diagnostics
- 🔧 Automated repair workflow
- ⚙ Windows service verification
- 📋 Progress window
- 📝 Log generation
- 🛡 Safe PowerShell execution

---

# 📸 Screenshots

### Architecture Overview

<p align="center">
  <img src="images/Phone%20Link%20and%20Bluetooth%20Doctor%20diag.png" width="90%">
</p>

---

# 🏗 Architecture

```text
RUN_PHONE_LINK_DOCTOR.bat
            │
            ▼
PhoneLink-Bluetooth-Doctor.ps1
            │
 ┌──────────┼──────────┐
 │          │          │
 ▼          ▼          ▼
Bluetooth  Phone Link  Windows
Checks      Checks     Services
 │          │          │
 └──────────┼──────────┘
            ▼
    Diagnostic Engine
            │
            ▼
    Automated Repairs
            │
            ▼
     Progress Window
            │
            ▼
        Log Results
```

---

# ⚙ Execution Pipeline

```text
Launch
   │
   ▼
Verify Administrator
   │
   ▼
Check Bluetooth
   │
   ▼
Check Phone Link
   │
   ▼
Verify Windows Services
   │
   ▼
Run Repairs
   │
   ▼
Generate Logs
   │
   ▼
Complete
```

---

# 📂 Project Structure

```text
PhoneLink-Bluetooth-Doctor-v1.0.0
│
├── .gitignore
├── LICENSE
├── README.md
├── RUN_PHONE_LINK_DOCTOR.bat
│
├── config
│   └── .gitkeep
│
├── images
│   └── Phone Link and Bluetooth Doctor diag.png
│
├── logs
│   └── .gitkeep
│
└── scripts
    ├── PhoneLink-Bluetooth-Doctor.ps1
    └── PhoneLink-Progress.ps1
```

---

# 💾 Installation

```powershell
git clone https://github.com/tcdoverlord/Windows-Bluetooth-PhoneLink-Doctor.git

cd Windows-Bluetooth-PhoneLink-Doctor
```

---

# ▶ Quick Start

Launch the application by running:

```text
RUN_PHONE_LINK_DOCTOR.bat
```

Or from PowerShell:

```powershell
.\RUN_PHONE_LINK_DOCTOR.bat
```

---

# 🛣 Roadmap

| Version | Status |
|---------|--------|
| v1.0.0 | ✅ Initial Release |
| v1.1.0 | ⬜ Enhanced diagnostics |
| v1.2.0 | ⬜ Driver repair improvements |
| v2.0.0 | ⬜ Modular repair engine & GUI |

---

# 📜 Version History

| Version | Description |
|---------|-------------|
| 1.0.0 | Initial public release with Bluetooth diagnostics, Phone Link diagnostics, automated repairs, progress UI, and logging. |

---

# 📄 License

Copyright © 2026 **TCDOVERLORD**

This project is released under the **TCDOVERLORD Personal Use License**.

- ✅ Personal Use
- ✅ Educational Use
- ✅ Learning
- ❌ Commercial Use without permission

---

# 👤 Author

## TCDOVERLORD

Building practical Windows automation tools for developers, IT professionals, and power users.

> **We Automate So You Don't Have To.**

---

# ❤️ Support

If this project helped you:

- ⭐ Star the repository
- 🐞 Report bugs through GitHub Issues
- 💡 Submit feature requests
- 🤝 Share the project with others

---

# ⭐ Star History

Star history will be added as the project grows.