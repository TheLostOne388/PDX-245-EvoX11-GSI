# Evolution X Android 16 GSI Configuration for Sony Xperia 1 VI (PDX245)
#
# Last updated: Dec 21, 2025
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

# Flag to indicate GApps build (removes "-Vanilla" suffix from version string)
WITH_GMS := true

# Bypass strict <uses-library> checks for GApps prebuilts
PRODUCT_BROKEN_VERIFY_USES_LIBRARIES := true

# ==============================================================================
# Device-Specific Overlays
# ==============================================================================
# Enables auto-brightness (curves from vendor displayconfig)
PRODUCT_PACKAGE_OVERLAYS += device/sony/pdx245/overlay

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
# Spoof ALL build properties to match stock Sony firmware 69.2.A.2.41 for enterprise compliance.
# This helps pass SafetyNet/Play Integrity "Basic Integrity" checks.
# Updated: Dec 21, 2025 - Firmware 69.2.A.2.41 (was 67.1.A.2.76)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.build.fingerprint=Sony/XQ-EC72/XQ-EC72:14/69.2.A.2.41/069002A002004101757534660:user/release-keys \
    ro.system.build.fingerprint=Sony/XQ-EC72/XQ-EC72:14/69.2.A.2.41/069002A002004101757534660:user/release-keys \
    ro.build.description=XQ-EC72-user_14_69.2.A.2.41_069002A002004101757534660_release-keys \
    ro.build.display.id=69.2.A.2.41

# ==============================================================================
# PHH Secure Mode (Hides su binary and hardens props at runtime)
# ==============================================================================
# This file triggers rw-system.sh to hide /system/xbin/su and set secure props
PRODUCT_COPY_FILES += \
    device/sony/pdx245/files/secure:$(TARGET_COPY_OUT_SYSTEM)/phh/secure

# ==============================================================================
# Launcher and Navigation Fix
# ==============================================================================
# Launcher3QuickStep (Trebuchet) crashes on Android 16 when using gesture navigation
# due to "UnsupportedOperationException: Tried to obtain display from a Context"
#
# Fix applied in rw-system.sh at boot for pineapple (SM8650) devices:
#   cmd overlay disable com.android.internal.systemui.navbar.gestural
#   cmd overlay enable com.android.internal.systemui.navbar.threebutton
#   settings put secure navigation_mode 0
#
# Note: ro.boot.vendor.overlay.theme doesn't work (bootloader property)

# Remove default launchers - use Lawnchair instead
# Trebuchet/Launcher3QuickStep crashes on Android 16 with gesture navigation
PRODUCT_PACKAGES := $(filter-out Launcher3QuickStep Launcher3 Trebuchet,$(PRODUCT_PACKAGES))

# Use Lawnchair as default launcher
# APK must be placed in device/sony/pdx245/packages/Lawnchair/Lawnchair.apk
PRODUCT_PACKAGES += \
    Lawnchair

# Force software navbar (device has no hardware keys)
PRODUCT_PRODUCT_PROPERTIES += \
    qemu.hw.mainkeys=0

# ==============================================================================
# Audio / Bluetooth Configuration
# ==============================================================================
# Force sysbta (system-side Bluetooth audio) instead of vendor Qualcomm offload.
# These are the same properties PHH's TrebleApp sets when "Use system-wide BT HAL" is enabled.
# We set them at build time since we don't have root to use resetprop_phh.
#
# Audio policy modification (add sysbta module) is done in rw-system.sh + vndk.rc
PRODUCT_PRODUCT_PROPERTIES += \
    persist.bluetooth.a2dp_offload.disabled=true \
    ro.bluetooth.a2dp_offload.supported=false \
    persist.bluetooth.bluetooth_audio_hal.disabled=true \
    persist.bluetooth.system_audio_hal.enabled=true

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

# Bluetooth Audio - Force sysbta (Software Bluetooth Audio)
# Sony vendor HAL exists but fails to open A2DP stream on GSI
# sysbta provides software A2DP encoding as workaround
#
# Note: Hardware offload would require Sony's libbluetooth_qti.so + btconfigstore HAL
# which are not available in AOSP GSI (APEX is signed/immutable)
PRODUCT_PRODUCT_PROPERTIES += \
    persist.bluetooth.avrcpversion=avrcp16 \
    persist.bluetooth.disableinbandringing=false \
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

# ==============================================================================
# Sony Camera App (from XQ-EC72_Customized_SEA_69.2.A.2.30 firmware)
# ==============================================================================
# Main camera app and dependencies extracted from stock Sony firmware.
# Requires com.sony.device framework JAR and various permission definitions.
PRODUCT_PACKAGES += \
    SomcCameraApp \
    CameraCommon \
    CameraPanorama \
    CameraAddonPermission \
    CameraCommonPermission \
    SomcCameraCalibration \
    com.sony.device.xml \
    privapp_whitelist_jp.co.sony.mc.cameraapp

# Sony framework JAR required by camera app (uses-library com.sony.device)
PRODUCT_COPY_FILES += \
    device/sony/pdx245/packages/SonyCameraApp/framework/com.sony.device.jar:$(TARGET_COPY_OUT_PRODUCT)/framework/com.sony.device.jar

# ==============================================================================
# Sony SmartCharger / Battery Care (from XQ-EC72_Customized_SEA_69.2.A.2.41 firmware)
# ==============================================================================
# Enables Battery Care feature in Settings > Battery:
# - Set charge limit to 80% or 90%
# - Adaptive charging based on usage patterns
#
# REQUIREMENTS:
# - Sony vendor partition with aidlcharger HAL service
# - Kernel support for /sys/class/battchg_ext/smart_charging_status
#
# NOTE: This is EXPERIMENTAL. May not work if vendor HAL isn't accessible.
PRODUCT_PACKAGES += \
    SmartCharger \
    com.sonyericsson.idd.xml \
    com.sonymobile.miscta.xml \
    jp.co.sony.mc.misctasdklibrary.xml \
    com.sonymobile.system_ext_idd.xml \
    com.sonymobile.vendor_idd.xml

# Sony framework JARs required by SmartCharger
PRODUCT_COPY_FILES += \
    device/sony/pdx245/packages/SmartCharger/framework/com.sonyericsson.idd_impl.jar:$(TARGET_COPY_OUT_PRODUCT)/framework/com.sonyericsson.idd_impl.jar \
    device/sony/pdx245/packages/SmartCharger/framework/com.sonymobile.miscta_impl.jar:$(TARGET_COPY_OUT_PRODUCT)/framework/com.sonymobile.miscta_impl.jar \
    device/sony/pdx245/packages/SmartCharger/framework/jp.co.sony.mc.misctasdklibrary.jar:$(TARGET_COPY_OUT_PRODUCT)/framework/jp.co.sony.mc.misctasdklibrary.jar

# ==============================================================================
# Sony Keylayout (Camera Button Support)
# ==============================================================================
# Maps physical camera button key codes:
#   key 528 -> FOCUS (half-press)
#   key 766 -> CAMERA (full-press to capture)
PRODUCT_COPY_FILES += \
    device/sony/pdx245/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/gpio-keys.kl

