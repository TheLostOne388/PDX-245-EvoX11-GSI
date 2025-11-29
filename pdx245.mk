# Evolution X Android 16 GSI Configuration for Sony Xperia 1 VI (PDX245)
#
# Last updated: Nov 27, 2025
#
# ==============================================================================
# PATCHES REQUIRED AFTER REPO SYNC (2 patches)
# ==============================================================================
# Run these commands from ~/Evo16 after every repo sync:
#
# cd ~/Evo16
#
# # 1. WiFi Country Code Override (prevents Indonesia country lock)
# cd packages/modules/Wifi
# git apply ../../../device/sony/pdx245/patches/wifi-country-code-override.patch
# cd ../../..
#
# # 2. WiFi 6GHz Framework Support (enables WiFi 6E/7)
# cd vendor/hardware_overlay
# git apply ../../device/sony/pdx245/patches/wifi-6ghz-overlay.patch
# cd ../..
#
# Note: NavBar patch eliminated - works with qemu.hw.mainkeys=0 + Trebuchet
# Note: WiFi 6GHz country list is now in PRODUCT_PRODUCT_PROPERTIES (no patch needed)
#
# ==============================================================================

# ==============================================================================
# Base GSI Target
# ==============================================================================
$(call inherit-product, device/phh/treble/treble_arm64_bgN.mk)

# Include GApps Pico (smaller footprint)
$(call inherit-product, vendor/gms/gms_pico.mk)

# Bypass strict <uses-library> checks for GApps prebuilts
PRODUCT_BROKEN_VERIFY_USES_LIBRARIES := true

# ==============================================================================
# Product Identity
# ==============================================================================
PRODUCT_NAME := pdx245
PRODUCT_DEVICE := pdx245
PRODUCT_BRAND := Sony
PRODUCT_MODEL := Xperia 1 VI
PRODUCT_MANUFACTURER := Sony
BUILDING_LINEAGE_GSI := true

# ==============================================================================
# Build Fingerprint & Identity (For Intune/Play Integrity Compliance)
# ==============================================================================
# Spoof ALL build properties to match stock Sony firmware for enterprise compliance.
# This helps pass SafetyNet/Play Integrity "Basic Integrity" checks.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.build.fingerprint=Sony/XQ-EC72/XQ-EC72:14/67.1.A.2.76/067001A002007604104057462:user/release-keys \
    ro.system.build.fingerprint=Sony/XQ-EC72/XQ-EC72:14/67.1.A.2.76/067001A002007604104057462:user/release-keys \
    ro.build.description=XQ-EC72-user_14_67.1.A.2.76_067001A002007604104057462_release-keys \
    ro.build.display.id=67.1.A.2.76

# ==============================================================================
# PHH Secure Mode (Hides su binary and hardens props at runtime)
# ==============================================================================
# This file triggers rw-system.sh to hide /system/xbin/su and set secure props
PRODUCT_COPY_FILES += \
    device/sony/pdx245/files/secure:$(TARGET_COPY_OUT_SYSTEM)/phh/secure

# ==============================================================================
# Launcher Fix
# ==============================================================================
# Use Trebuchet (Launcher3QuickStep) as the default and only launcher
# NexusLauncherOverride is a stub package that prevents Pixel Launcher from being built
PRODUCT_PACKAGES += \
    Launcher3QuickStep \
    NexusLauncherOverride

# ==============================================================================
# Sony Stock Product Partition Properties
# ==============================================================================
# These properties are normally in Sony's stock product partition.
# GSI replaces product partition, so we must restore them here.

# WiFi 6GHz / WiFi 7 Country Lists (CRITICAL for WiFi 7!)
# Adding US to both lists for US WiFi 6E/7 support
PRODUCT_PRODUCT_PROPERTIES += \
    ro.vendor.sony.wlan.6e_cc_list=US,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,GB,CH,IS,MY,TH,TW,SG,MO \
    ro.vendor.sony.wlan.11be_cc_list=US,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,GB,CH,IS,TH,TW,SG,MO,MY

# Device Identity (from stock SEA firmware)
PRODUCT_PRODUCT_PROPERTIES += \
    ro.semc.product.device=EC \
    ro.semc.product.model=XQ-EC72 \
    ro.semc.product.name=Xperia_1_VI \
    ro.semc.version.sw_variant=GLOBAL-C2 \
    ro.semc.ms_type_id=PM-1492-BV \
    ro.semc.content.number=PA5

# Display / Color Calibration
PRODUCT_PRODUCT_PROPERTIES += \
    persist.sony.display.recommended_settings=false \
    persist.sony.user_fpsmode=true

# Bluetooth Audio
PRODUCT_PRODUCT_PROPERTIES += \
    persist.bluetooth.avrcpversion=avrcp16 \
    persist.bluetooth.disableinbandringing=false \
    persist.bluetooth.leaudio_offload.disabled=false \
    persist.bluetooth.bqr.event_mask=295006 \
    persist.bluetooth.bqr.min_interval_ms=500 \
    persist.bluetooth.iso_link_quality_report=true \
    persist.bluetooth.leaudio.bypass_allow_list=true \
    persist.bluetooth.leaudio.notify.idle.during.call=true \
    persist.enable.bluetooth.voipleawar=true

# Window Manager
PRODUCT_PRODUCT_PROPERTIES += \
    persist.wm.extensions.enabled=true

# Framework country code override (prevents ID lock)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.wifi.country_code_override=US \
    ro.boot.wificountrycode=US

# Fallback: Also set WiFi properties in system in case product isn't read early enough
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.vendor.sony.wlan.6e_cc_list=US,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,GB,CH,IS,MY,TH,TW,SG,MO \
    ro.vendor.sony.wlan.11be_cc_list=US,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,GB,CH,IS,TH,TW,SG,MO,MY

# ==============================================================================
# Navigation Bar
# ==============================================================================
# qemu.hw.mainkeys=0 tells Android this device has no hardware keys (show navbar)
# Works without static overlay patch when using Trebuchet launcher
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    qemu.hw.mainkeys=0

# ==============================================================================
# Sony PDX245 Telephony
# ==============================================================================
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.telephony.default_network=26,26 \
    persist.vendor.dpm.feature=0 \
    persist.vendor.rcs.singlereg.feature=1

# Re-enable QcRilAm for Qualcomm voice call audio routing
PRODUCT_PACKAGES += QcRilAm

