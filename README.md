# Sony Xperia 1 VI (PDX245) - Evolution X GSI Device Tree

Device tree for building Evolution X Android 16 GSI for Sony Xperia 1 VI (PDX245).

## Status

| Feature | Status | Notes |
|---------|--------|-------|
| Telephony | ✅ Working | Dual SIM, 5G/4G/LTE, Calls |
| WiFi 2.4/5GHz | ✅ Working | Full support |
| WiFi 6GHz (WiFi 7) | ✅ Working | 6GHz bands enabled via product properties |
| Bluetooth Audio | ✅ telephone only | A2DP still inop
| Fingerprint | ✅ Working | 
| Navigation Bar | ✅ Working | 3-button navigation with Lawnchair |
| Launcher | ✅ Working | Lawnchair (Trebuchet removed ) |
| Audio | ✅ Working | Stereo speakers |
| Display | ✅ Working | Full resolution, HDR, 120Hz |
| Auto-Brightness | ✅ Working | Brightness curves via overlay |
| Battery Care | ✅ Working | Sony SmartCharger (80%/90% limit) |
| Camera | ✅ Working | Sony Camera app from stock firmware |
| SELinux | ✅ Enforcing | Full security compliance |
| Intune/Enterprise | ✅ Working | Passes Microsoft Intune compliance checks |

## Patches Required After Repo Sync

Run these commands after every `repo sync`:

```bash
cd ~/Evo16

# 1. WiFi Country Code Override (enables Wi-Fi 7 everywhere)
cd packages/modules/Wifi
git apply ../../../device/sony/pdx245/patches/wifi-country-code-override.patch
cd ../../..

# 2. WiFi 6GHz Framework Support (enables WiFi 6E/7)
cd vendor/hardware_overlay
git apply ../../device/sony/pdx245/patches/wifi-6ghz-overlay.patch
cd ../..

# 3. AOD Brightness & Screensaver Fixes
cd frameworks/base
git apply ../../device/sony/pdx245/patches/frameworks_base_PowerManagerService.patch
git apply ../../device/sony/pdx245/patches/frameworks_base_DozeScreenBrightness.patch
git apply ../../device/sony/pdx245/patches/frameworks_base_EdgeLightViewController.patch
cd ../..

# 4. Security Patch Level Display Fix
cd device/phh/treble
git apply ../../../device/sony/pdx245/patches/device_phh_treble_rw-system.patch
cd ../../..

# 5. Biometric Prompt Location (Side-mounted fingerprint indicator)
cd frameworks/base
git apply ../../device/sony/pdx245/patches/frameworks_base_BiometricPromptLocation.patch
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
├── keylayout/
│   └── gpio-keys.kl              # Camera button keylayout
├── overlay/                      # Static overlays (brightness curves)
├── overlay-fingerprint/          # Fingerprint RRO (config_sfps_sensor_props)
├── overlay-systemui/             # SystemUI RRO (fingerprint location dimens)
├── patches/                      # Required framework patches
│   ├── wifi-country-code-override.patch
│   ├── wifi-6ghz-overlay.patch
│   ├── frameworks_base_*.patch   # AOD/brightness fixes
│   ├── device_phh_treble_rw-system.patch
│   └── frameworks_base_BiometricPromptLocation.patch
└── packages/
    ├── Lawnchair/                # Default launcher APK
    ├── SonyCameraApp/            # Stock Sony camera
    └── SmartCharger/             # Battery care app
```

## Build Instructions

```bash
# 1. Initialize repo
repo init -u https://github.com/Evolution-X/manifest -b udc --git-lfs
repo sync -c -j$(nproc --all)

# 2. Clone this device tree
git clone https://github.com/TheLostOne388/PDX-245-EvoX11-GSI.git device/sony/pdx245

# 3. Apply patches (REQUIRED after every repo sync)
# See "Patches Required After Repo Sync" section above

# 4. Build
source build/envsetup.sh
lunch pdx245-user          # Use 'user' for Intune compliance
make installclean
make -j$(nproc --all) systemimage
```

**Output:** `out/target/product/pdx245/system.img`

**Note:** Use `pdx245-user` for production/Intune compliance. Use `pdx245-userdebug` only for development/debugging.

## Credits
- **phhusson** - Treble GSI framework, resetprop_phh
- **TrebleDroid Team** - Android 16 GSI support
- **Evolution X Team** - ROM base
