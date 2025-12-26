# Sony Xperia 1 VI (PDX245) - Evolution X GSI Device Tree

Device tree for building Evolution X Android 16 GSI for Sony Xperia 1 VI (PDX245).

## Status

| Feature | Status | Notes |
|---------|--------|-------|
| Telephony | ✅ Working | Dual SIM, 5G/4G/LTE, Calls |
| WiFi 2.4/5GHz | ✅ Working | Full support |
| WiFi 6GHz (WiFi 7) | ✅ Working | 6GHz bands enabled via product properties |
| Navigation Bar | ✅ Working | No patch needed with Trebuchet launcher |
| Launcher | ✅ Working | (Pixel / Lawnchair Launcher) |
| Audio | ✅ Working | Stereo speakers |
| Display | ✅ Working | Full resolution, HDR, 120Hz |
| SELinux | ✅ Enforcing | Full security compliance |
| Intune/Enterprise | ✅ Working | Passes Microsoft Intune compliance checks |

## Patches Required After Repo Sync

Run these commands after every `repo sync`:

```bash
cd /path/to/Evo16

# 1. WiFi Country Code Override (prevents ID lock)
cd packages/modules/Wifi
git apply ../../../device/sony/pdx245/patches/wifi-country-code-override.patch
cd ../../..

# 2. WiFi 6GHz Framework Support
cd vendor/hardware_overlay
git apply ../../device/sony/pdx245/patches/wifi-6ghz-overlay.patch
cd ../..
```

## File Structure

```
device/sony/pdx245/
├── Android.bp                    # Soong build configuration
├── AndroidProducts.mk            # Product list (pdx245-user, pdx245-userdebug)
├── BoardConfig.mk                # Board configuration
├── pdx245.mk                     # Main device makefile
├── README.md                     # This file
├── apns/                         # Custom APN configurations
├── files/
│   └── secure                    # PHH secure mode marker (Intune compliance)
├── patches/                      # Required patches
│   ├── wifi-country-code-override.patch
│   └── wifi-6ghz-overlay.patch
├── packages/
│   └── NexusLauncherOverride/    # Stub to exclude Pixel Launcher
└── documentation/
    ├── INTUNE_TROUBLESHOOTING.md # Enterprise compliance guide
    └── wifi_nav_troubleshooting.md
```

## Build Instructions

```bash
# 1. Initialize repo
repo init -u https://github.com/Evolution-X/manifest -b udc --git-lfs
repo sync -c -j$(nproc --all)

# 2. Clone this device tree
git clone https://github.com/TheLostOne388/PDX-245-EvoX11-GSI.git device/sony/pdx245

# 3. Apply patches (REQUIRED after every repo sync)
cd packages/modules/Wifi
git apply ../../../device/sony/pdx245/patches/wifi-country-code-override.patch
cd ../../..

cd vendor/hardware_overlay
git apply ../../device/sony/pdx245/patches/wifi-6ghz-overlay.patch
cd ../..

# 4. Build
source build/envsetup.sh
lunch pdx245-user          # Use 'user' for Intune compliance (or 'userdebug' for development)
make installclean
make -j$(nproc --all) systemimage
```

**Output:** `out/target/product/pdx245/system.img`

**Note:** Use `pdx245-user` for production/Intune compliance. Use `pdx245-userdebug` only for development/debugging.

## Credits
- **phhusson** - Treble GSI framework, resetprop_phh
- **TrebleDroid Team** - Android 16 GSI support
- **Evolution X Team** - ROM base
