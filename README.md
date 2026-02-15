# Sony Xperia 1 VI (PDX245) - Evolution X GSI Device Tree

Device tree for building Evolution X Android 16 QPR2 GSI for Sony Xperia 1 VI (PDX245 / XQ-EC72).

**Branch:** `bq2` (Android 16 QPR2, `android-16.0.0_r4`, BP4A)
**Base firmware:** Sony 69.2.A.4.1 (SEA)
**SoC:** Snapdragon 8 Gen 3 (SM8650 / pineapple)

## Status

| Feature | Status | Notes |
|---------|--------|-------|
| Telephony | ✅ Working | Dual SIM, 5G/4G/LTE, voice, data. Requires stock boot priming (see below) |
| WiFi 2.4/5GHz | ✅ Working | Full support |
| WiFi 6GHz (WiFi 7) | ✅ Working | Region blocks removed
| Bluetooth Pairing | ✅ Working | BT connections, SCO call audio |
| Bluetooth A2DP | ❌ Not working | Media audio over BT inoperable on all GSI builds.
| Fingerprint | ✅ Working | Side-mounted sensor, biometric prompt location patched |
| Navigation Bar | ✅ Working | all nav modes working |
| Launcher | ✅ Working | Pixel / Lawnchair included (or use your own) |
| Speaker Audio | ✅ Working | Stereo speakers |
| Display | ✅ Working | Full resolution, HDR, 120Hz |
| Auto-Brightness | ✅ Working | Brightness curves via overlay |
| Battery Care | ✅ Working | Sony SmartCharger (80%/90% charge limit) |
| Camera | ✅ Working | Sony Camera app from stock firmware |
| SELinux | ✅ Enforcing | Full security compliance |
| Intune/Enterprise | ✅ Working | Passes Microsoft Intune compliance checks |
| Security Patch Level | ✅ Correct | Dynamic — auto-updates with platform version |
| ADB | 🔒 Secure | `ro.adb.secure=1` (authorization required) |

### Known Limitations

- **Bluetooth A2DP:** Media audio over Bluetooth does not work on any GSI for
  this device. BT call audio (SCO) works. This is a community-wide issue with
  SM8650 GSI builds — no known fix exists.

- **Telephony requires stock boot priming:** After a clean flash (wiped
  userdata), you must boot into stock Sony firmware once before flashing the GSI.
  This initializes modem NV data in `/data/vendor/` that the telephony stack
  requires. Dirty flashing over a working stock install also works.

## Patches Required After Repo Sync

Run these commands from your build root (e.g. `~/Evo16Q2`) after every
`repo sync`. All patches are stored in `device/sony/pdx245/patches/`.

```bash
# 1. WiFi Country Code Override (prevents Indonesia country lock on WiFi 7)
cd packages/modules/Wifi
git apply ../../../device/sony/pdx245/patches/wifi-country-code-override.patch
cd ../../..

# 2. WiFi 6GHz Framework Support (enables WiFi 6E/7 band scanning)
cd vendor/hardware_overlay
git apply ../../device/sony/pdx245/patches/wifi-6ghz-overlay.patch
cd ../..

# 3. AOD Brightness & Screensaver Fixes
cd frameworks/base
git apply ../../device/sony/pdx245/patches/frameworks_base_PowerManagerService.patch
git apply ../../device/sony/pdx245/patches/frameworks_base_DozeScreenBrightness.patch
git apply ../../device/sony/pdx245/patches/frameworks_base_EdgeLightViewController.patch
cd ../..

# 4. Security Patch Level Display Fix (prevents rw-system.sh from overwriting platform SPL)
cd device/phh/treble
git apply ../../../device/sony/pdx245/patches/device_phh_treble_rw-system.patch
cd ../../..

# 5. Biometric Prompt Location (side-mounted fingerprint sensor indicator)
cd frameworks/base
git apply ../../device/sony/pdx245/patches/frameworks_base_BiometricPromptLocation.patch
cd ../..
```

**Tip:** To verify patches are applied: `git apply --check <patch>` returns
error if already applied, silent if ready to apply.

## File Structure

```
device/sony/pdx245/
├── Android.bp                    # Soong build config (QPR2: stub removed)
├── AndroidProducts.mk            # Product list (pdx245-user, pdx245-userdebug)
├── BoardConfig.mk                # Board config, SELinux dirs, system_ext.prop override
├── pdx245.mk                     # Main device makefile (all features configured here)
├── README.md                     # This file
├── init.pdx245.rc                # Init service for runtime property fixup
├── pdx245-fixup-props.sh         # Runtime property + audio policy fixup script
├── system_ext.prop               # Custom system_ext properties (secure ADB)
├── apns/                         # Custom APN configurations
├── documents/                    # Build fixes, troubleshooting docs
│   ├── qpr2-build-fixes.md       # All build & runtime fixes (Fixes 1-14)
│   ├── a2dp-bluetooth-troubleshooting.md  # Comprehensive A2DP history
│   └── stock-reference-fw69.2.A.4.1.md    # Stock firmware reference
├── files/
│   └── secure                    # PHH secure mode marker (hides su, Intune compliance)
├── keylayout/
│   └── gpio-keys.kl              # Camera button keylayout (focus + capture)
├── overlay/                      # Static overlays (brightness curves)
├── overlay-fingerprint/          # Fingerprint RRO (config_sfps_sensor_props)
├── overlay-systemui/             # SystemUI RRO (fingerprint location dimens)
├── patches/                      # Framework patches (apply after repo sync)
├── packages/
│   ├── Lawnchair/                # Default launcher APK
│   ├── SonyCameraApp/            # Stock Sony camera + dependencies
│   └── SmartCharger/             # Battery care app + framework JARs
├── sepolicy/                     # Vendor SELinux policy extensions
├── sepolicy_system_ext/          # System_ext SELinux policy (telephony HAL access)
│   └── telephony.te              # typeattribute platform_app hal_telephony_client
└── stock_telephony/              # Qualcomm telephony stack from stock firmware
    ├── product_framework/        # Framework JARs (UIM, radio, etc.)
    ├── product_permissions/      # Permission XMLs for shared libraries
    └── system_ext_apks/          # IMS + qcrilmsgtunnel APKs (BUILD_PREBUILT)
```

## Runtime Fixup Script

`pdx245-fixup-props.sh` runs at `boot_completed` under the `phhsu_daemon`
SELinux domain (permissive) to set properties that SELinux enforcing mode blocks
from build.prop. It handles:

- **Bluetooth:** sysbta properties, audio policy patching (A2DP attempt)
- **WiFi 6GHz:** `ro.vendor.sony.wlan.6e_cc_list` / `11be_cc_list`
- **Telephony:** `ro.boot.vendor.qspa.modem=enabled` (IMS overlay loading)
- **SPL:** Restores correct platform security patch level + PIHooks override

Log output: `/data/local/tmp/pdx245-fixup.log` (readable via `adb shell`)

## Build Instructions

```bash
# 1. Initialize repo (QPR2 branch)
repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs
repo sync -c -j$(nproc --all)

# 2. Clone this device tree (bq2 branch)
git clone -b bq2 https://github.com/TheLostOne388/PDX-245-EvoX11-GSI.git \
    device/sony/pdx245

# 3. Apply patches (REQUIRED after every repo sync)
# See "Patches Required After Repo Sync" section above

# 4. Build
source build/envsetup.sh
lunch pdx245-userdebug
mka systemimage
```

**Output:** `out/target/product/pdx245/system.img`

## Flashing

```bash
# Prerequisites: Sony firmware 69.2.A.4.1 flashed, bootloader unlocked,
# stock booted at least once (for modem NV data)

# 1. Reboot to fastboot
adb reboot fastboot

# 2. Flash system image
fastboot flash system system.img

# 3. Reboot
fastboot reboot
```

## Branch History

| Branch | Android | QPR | Base | Status |
|--------|---------|-----|------|--------|
| `bka` | 16 | QPR1 | `android-16.0.0_r3` (BP3A) | Previous — working |
| `bq2` | 16 | QPR2 | `android-16.0.0_r4` (BP4A) | **Current** |


## Credits

- **phhusson** - Treble GSI framework, resetprop_phh, sysbta
- **TrebleDroid Team** - Android 16 GSI support, phh-prop-handler
- **Evolution X Team** - ROM base, Play Integrity hooks
- **Qualcomm / CodeAurora** - Telephony framework (vendor/codeaurora/telephony)
