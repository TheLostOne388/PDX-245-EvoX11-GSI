# Evolution X Android 16 GSI Configuration for Sony Xperia 1 VI (PDX245)
#
# Last updated: Dec 21, 2025
#
# ==============================================================================
# PATCHES REQUIRED AFTER REPO SYNC (3 sets of patches)
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
# # 3. AOD Brightness & Screensaver Fixes (AOD too bright, screensaver priority)
# cd frameworks/base
# git apply ../../device/sony/pdx245/patches/frameworks_base_PowerManagerService.patch
# git apply ../../device/sony/pdx245/patches/frameworks_base_DozeScreenBrightness.patch
# git apply ../../device/sony/pdx245/patches/frameworks_base_EdgeLightViewController.patch
# cd ../..
#
# # 4. Fix Security Patch Level Display (Prevents downgrade to vendor SPL)
# cd device/phh/treble
# git apply ../../../device/sony/pdx245/patches/device_phh_treble_rw-system.patch
# cd ../../..
#
# # 5. Biometric Prompt Location (Side-mounted fingerprint sensor indicator)
# cd frameworks/base
# git apply ../../device/sony/pdx245/patches/frameworks_base_BiometricPromptLocation.patch
# cd ../..
#
# Note: NavBar patch eliminated - works with qemu.hw.mainkeys=0 + Trebuchet
# Note: WiFi 6GHz country list is now in PRODUCT_PRODUCT_PROPERTIES (no patch needed)
#
# ==============================================================================

# ==============================================================================
# Base GSI Target
# ==============================================================================
# Vanilla (no GApps) arm64 AB target.
$(call inherit-product, device/phh/treble/treble_arm64_bvN.mk)

# ==============================================================================
# Device-Specific Overlays
# ==============================================================================
# Enables auto-brightness (curves from vendor displayconfig)
PRODUCT_PACKAGE_OVERLAYS += device/sony/pdx245/overlay

# Runtime Resource Overlay for Fingerprint Configuration (Ensures it overrides framework defaults)
PRODUCT_PACKAGES += \
    SonyFingerprintOverlay \
    SonySystemUIOverlay

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
# SELinux Property Fixup
# ==============================================================================
# SELinux enforcing mode blocks certain property namespaces (ro.vendor.*,
# persist.bluetooth.*) from loading via build.prop. This script runs under the
# phhsu_daemon SELinux context (which is permissive) to set them at boot.
PRODUCT_COPY_FILES += \
    device/sony/pdx245/pdx245-fixup-props.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/pdx245-fixup-props.sh \
    device/sony/pdx245/init.pdx245.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.pdx245.rc

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

# IMS Feature Declaration: filter-out DOES NOT WORK (inherit-product timing)
# The IMS feature XML is added by device/phh/treble/base.mk via
# inherit-product. Android's inherit-product stores variables in a
# separate namespace (PRODUCTS.<product>.PRODUCT_COPY_FILES) and merges
# them AFTER all product makefiles finish loading. So this filter-out
# runs before the inherited entries are merged and has no effect.
# The file still appears at /system/etc/permissions/android.hardware.telephony.ims.xml.
#
# This is harmless now that StockIms is removed: without an IMS service APK,
# the feature declaration has no effect (no ImsService to bind to).
# If we ever need to truly remove this feature, modify base.mk directly
# (fragile -- reverted by repo sync).
PRODUCT_COPY_FILES := $(filter-out frameworks/native/data/etc/android.hardware.telephony.ims.xml:system/etc/permissions/android.hardware.telephony.ims.xml,$(PRODUCT_COPY_FILES))

# ==============================================================================
# Stock Qualcomm Telephony Stack -- DISABLED (QPR2 regression revert)
# ==============================================================================
# These QPR2 additions (framework JARs, permissions, qcrilmsgtunnel, StockIms,
# SELinux policy) were extracted from Sony firmware and added to provide
# Qualcomm's telephony stack on the GSI. However, they cause a critical
# regression: the vendor IMS daemons partially initialize and tell the modem
# to route incoming SMS through IMS. Since IMS never fully registers on the
# GSI (CODE_REGISTRATION_ERROR), incoming SMS is silently dropped at the
# modem level before it reaches Android.
#
# On QPR1 (none of these additions present), CS (circuit-switched) SMS
# worked perfectly. Reverting to QPR1 state restores SMS receive.
#
# Disabled: Feb 16, 2026
# See documents/qpr2-build-fixes.md Fix 16 for full analysis.
#
# --- Qualcomm Telephony Framework (built from source) ---
# PRODUCT_PACKAGES += \
#     ims-ext-common \
#     ims_ext_common.xml \
#     extphonelib-product \
#     extphonelib_product.xml \
#     qti-telephony-hidl-wrapper-prd \
#     qti_telephony_hidl_wrapper_prd.xml \
#     qti-telephony-utils-prd \
#     qti_telephony_utils_prd.xml
#
# --- System_ext variants ---
# PRODUCT_PACKAGES += \
#     extphonelib \
#     extphonelib.xml \
#     qti-telephony-hidl-wrapper \
#     qti_telephony_hidl_wrapper.xml \
#     qti-telephony-utils \
#     qti_telephony_utils.xml
#
# --- Product Framework JARs (stock prebuilts) ---
# PRODUCT_COPY_FILES += \
#     device/sony/pdx245/stock_telephony/product_framework/*.jar (9 JARs)
#
# --- Product Permissions ---
# PRODUCT_COPY_FILES += \
#     device/sony/pdx245/stock_telephony/product_permissions/*.xml (7 XMLs)
#
# --- StockQcrilMsgTunnel (OEM hook handler) ---
# PRODUCT_PACKAGES += StockQcrilMsgTunnel
#
# --- StockIms (IMS service APK) ---
# PRODUCT_PACKAGES += StockIms
#
# --- libimsmedia_jni.so (native lib for StockIms) ---
# PRODUCT_COPY_FILES += ...libimsmedia_jni.so

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

