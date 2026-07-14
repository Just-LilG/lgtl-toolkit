# LilG Tech Labs Toolkit v3.0

A collection of advanced Android repair, recovery, and optimization scripts for Termux. Built and maintained by Lil G Tech Labs.

> **Private — for team use only.**

## Scripts

| Script | Purpose |
|--------|---------|
| `lgtl_install.sh` | Master launcher — start here |
| `lgtl_lib.sh` | Shared library (required by all scripts) |
| `frp.sh` | FRP bypass — 7 methods, brand-specific |
| `imei.sh` | IMEI repair/write — 6 methods, Luhn validation |
| `pin_remove.sh` | PIN/lock removal — 6 methods |
| `rom_flash.sh` | ROM & partition flashing — 5 operations |
| `lgtl_bootloader.sh` | Bootloader operations — 9 operations |
| `lgtl_unbrick.sh` | Unbrick & recovery — 5 methods |
| `lgtl_ai_sense.sh` | CPU performance profiles — 6 profiles |
| `lgtl_transsion_debloat.sh` | Transsion/XOS debloater |
| `Universal-debloat.sh` | 11-brand universal debloater |

## Setup

```bash
# Extract
unzip LilGTechLabs_v3.0_FIXED.zip
cd SCRIPTS_ONLY

# Make executable
chmod +x *.sh

# Launch
bash lgtl_install.sh
```

## Requirements

- Termux (Android terminal)
- ADB / Fastboot access where required
- Root access for some operations

## Verified Devices

- Samsung Galaxy S10–S24
- Xiaomi Redmi Note 5–13
- Infinix, Tecno, Itel (XOS)
- Oppo, Vivo, Realme
- Motorola, Sony, Nokia, LG
- Android 5.0 through Android 14

## Safety

All destructive operations require typed confirmation keywords (CONFIRM, WIPE, UNLOCK, etc.). Automatic backups are created before modifications where possible.

## Support

**Channel:** t.me/LilGTechLabs  
**Author:** Lil G · @Just_LiLGXX
