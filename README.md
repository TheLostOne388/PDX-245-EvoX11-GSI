# Sony Xperia 1 VI (PDX245) - Evolution X GSI Device Tree

Device tree for building Evolution X Android 16 GSI for Sony Xperia 1 VI (PDX245).

## Status

| Feature | Status | Notes |
|---------|--------|-------|
| Telephony | ✅ Working | Dual SIM, VoLTE, 5G/4G/LTE, SMS/MMS, Calls |
| WiFi 2.4/5GHz | ✅ Working | Full support |
| WiFi 6GHz (WiFi 7) | 🔧 In Progress | Requires init script to set vendor property |
| Navigation Bar | ✅ Working | No patch needed with Trebuchet launcher |
| Launcher | ✅ Working | Trebuchet (Pixel Launcher disabled via override) |
| Audio | ✅ Working | Stereo speakers, Bluetooth audio |
| Display | ✅ Working | Full resolution, HDR, 120Hz |

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

## Key Fixes Explained

### 1. Launcher (Pixel Launcher → Trebuchet)
- **Problem:** Pixel Launcher was unstable on this device (crashing, unresponsive)
- **Solution:** Created `NexusLauncherOverride` stub package that uses Android's `overrides` mechanism to exclude Pixel Launcher from the build
- **Location:** `packages/NexusLauncherOverride/`
- **No patches required** - fully self-contained in device tree

### 2. Navigation Bar
- **Problem:** Navigation bar didn't appear automatically
- **Solution:** Set `qemu.hw.mainkeys=0` property (tells Android no hardware keys)
- **No patches required** - works with Trebuchet launcher

### 3. WiFi 6GHz / WiFi 7
- **Problem:** Sony's WiFi driver requires `ro.vendor.sony.wlan.6e_cc_list` property to enable 6GHz bands. This property is set in stock firmware's product partition but is missing when using a GSI.
- **Root Cause:** Without this property, the driver's `BandCapability=7` (2.4G+5G+6G) doesn't enable 6GHz scanning
- **Solution:** Init script uses `resetprop_phh` to set this property at boot
- **Location:** `init.pdx245.rc`, `init.pdx245.wifi6ghz.sh`
- **Still requires 2 patches** for framework-level WiFi support

### 4. WiFi Country Code
- **Problem:** Indonesia (ID) locks WiFi to limited channels
- **Solution:** Framework patch adds `persist.sys.wifi.country_code_override` support
- **Requires patch** to `packages/modules/Wifi`

## Troubleshooting

### WiFi 6GHz Not Working

1. **Check if property is set:**
   ```bash
   adb shell getprop ro.vendor.sony.wlan.6e_cc_list
   ```
   Should return: `US,GB,HK,JP,AT,BE,BG,...` (list of countries)

2. **Check country code:**
   ```bash
   adb shell cmd wifi get-country-code
   ```
   Should return: `Wifi Country Code = US`

3. **Check if 6GHz channels are available:**
   ```bash
   adb shell dumpsys wifi | grep "SupportedChannelListIn6g"
   ```
   Should show channel numbers like `[1, 5, 9, 13, ...]` not empty `[]`

4. **Check logs:**
   ```bash
   adb logcat -s PDX245-WiFi6GHz
   ```

5. **Manual fix (if init script didn't run):**
   ```bash
   adb shell su -c "resetprop ro.vendor.sony.wlan.6e_cc_list 'US,GB,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,CH,IS,MY,TH,TW,SG,MO'"
   adb shell svc wifi disable
   adb shell svc wifi enable
   ```

### Navigation Bar Missing
- Should work automatically with `qemu.hw.mainkeys=0`
- If not showing, check in Phh Treble Settings → Misc features → Use navbar

### Launcher Issues
- Pixel Launcher should not appear (excluded via override package)
- If it still appears, verify `NexusLauncherOverride` is in the build

## File Structure

```
device/sony/pdx245/
├── Android.bp                    # Soong build configuration
├── AndroidProducts.mk            # Product list
├── BoardConfig.mk                # Board configuration
├── pdx245.mk                     # Main device makefile
├── README.md                     # This file
├── init.pdx245.rc                # Init script for WiFi 6GHz
├── init.pdx245.wifi6ghz.sh       # WiFi 6GHz property setter
├── apns/                         # Custom APN configurations
├── patches/                      # Required patches
│   ├── wifi-country-code-override.patch
│   └── wifi-6ghz-overlay.patch
└── packages/
    └── NexusLauncherOverride/    # Stub to exclude Pixel Launcher
```

## Build Instructions

```bash
# 1. Initialize repo
repo init -u https://github.com/Evolution-X/manifest -b udc --git-lfs
repo sync -c -j$(nproc --all)

# 2. Apply patches (REQUIRED after every repo sync)
cd packages/modules/Wifi
git apply ../../../device/sony/pdx245/patches/wifi-country-code-override.patch
cd ../../..

cd vendor/hardware_overlay
git apply ../../device/sony/pdx245/patches/wifi-6ghz-overlay.patch
cd ../..

# 3. Build
source build/envsetup.sh
lunch pdx245-userdebug
make installclean
make -j$(nproc --all) systemimage
```

**Output:** `out/target/product/pdx245/system.img`

## Credits
- **phhusson** - Treble GSI framework, resetprop_phh
- **TrebleDroid Team** - Android 16 GSI support
- **Evolution X Team** - ROM base
