# Ciphera - Premium Archive Extraction Utility

## Version: 5.0 (Production Ready)

---

## Overview

Ciphera is a premium archive extraction utility for macOS that automatically extracts password-protected archives with professional-grade organization and cloud sync capabilities.

## Features

### Core Features
- **Multi-format Support**: ZIP, RAR, 7Z, TAR, GZ, BZ2, XZ, ISO, DMG
- **Password Recovery**: Try multiple passwords with auto-variations
- **Smart Detection**: Skip partial downloads (.part, .crdownload, .download, .tmp)
- **Split Archive Support**: Handle .7z.001, .zip.001, .rar.001

### Organization
- **Watch/Trash/Failed**: Automatic file organization
- **macOS Color Tags**: Green (Watch), Blue (Trash), Red (Failed)
- **Extraction Logs**: Complete history with timestamps

### User Experience
- **Premium ASCII UI**: Color-coded terminal interface
- **Interactive Mode**: Finder dialogs for folder selection
- **Command-line Mode**: -s -p -t arguments
- **Real-time Progress**: Live password attempt counter

### Cloud Integration
- **Supabase Ready**: Database schema included
- **Cloud Sync**: Track extraction history
- **GitHub Backup**: Version controlled

---

## Installation

### Option 1: Double-click App
```
/Users/sgkrishna/AI Insfrastructure/Ciphera/Ciphera.app
```

### Option 2: Command Line
```bash
cd /Users/sgkrishna/AI Insfrastructure/Ciphera
bash Ciphera.sh -s "/path/to/archives" -p "/path/to/passwords.txt" -t "/path/to/output"
```

---

## Usage

### Interactive Mode
1. Double-click Ciphera.app
2. Select SOURCE folder (archives)
3. Select PASSWORD file (.txt)
4. Select TARGET folder

### Command Line Mode
```bash
bash Ciphera.sh -s "/Users/sgkrishna/Desktop/archives" -p "/Users/sgkrishna/Desktop/passwords.txt" -t "/Users/sgkrishna/Desktop/output"
```

---

## Architecture

```
Ciphera/
├── Ciphera.sh           # Main extraction engine
├── Ciphera.app/         # macOS application bundle
│   └── Contents/
│       ├── MacOS/Ciphera
│       └── Resources/Ciphera.sh
├── supabase/
│   ├── schema.sql      # Database tables
│   └── ciphera_supabase.sh  # Cloud sync module
├── engine/
│   ├── crystal_extract.sh
│   ├── guard_rails.sh
│   └── organize_files.sh
└── push_to_github.sh   # GitHub sync script
```

---

## Test Results (v5.0)

| Test | Result |
|------|--------|
| Archive Detection | ✅ 3/3 found |
| Password Match | ✅ "girls" matched |
| Extraction | ✅ 3/3 successful |
| Organization | ✅ Watch/Trash/Failed created |
| Log Generation | ✅ extraction_log.txt created |

---

## Roadmap

### Future Enhancements
- [ ] Supabase cloud sync integration
- [ ] Progress bar with percentage
- [ ] Concurrent extraction workers
- [ ] GUI application with SwiftUI
- [ ] iCloud backup

---

## Credits

- **Author**: krishnasureshcpa
- **GitHub**: https://github.com/krishnasureshcpa/Ciphera
- **License**: MIT
