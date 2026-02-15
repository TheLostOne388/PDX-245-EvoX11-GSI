#!/system/bin/sh
# PDX245 property fixup script
# Runs under phhsu_daemon SELinux context (permissive) to set properties
# that are blocked by SELinux enforcing mode property_contexts.
#
# These properties are in the build.prop files but get silently dropped
# at boot because their namespaces (ro.vendor.*, persist.bluetooth.*)
# require vendor or bluetooth SELinux contexts to set.
#
# NOTE ON VERIFICATION: adb shell runs as u:r:shell:s0 which CANNOT read
# properties in bluetooth_prop or vendor_default_prop contexts. Running
# "adb shell getprop persist.bluetooth.system_audio_hal.enabled" returns
# empty even when the property IS set. Verify by reading this script's
# log at /data/local/tmp/pdx245-fixup.log instead (verification section
# runs as phhsu_daemon and CAN read all properties).

# --- Logging ---
# Log output for debugging. /cache is on the read-only rootfs, so use
# /data/local/tmp/ which is always writable. Fall back gracefully if
# even that fails so the script still runs the property commands.
LOG=/data/local/tmp/pdx245-fixup.log
if echo "=== pdx245-fixup-props.sh started at $(date) ===" > "$LOG" 2>/dev/null; then
    exec >> "$LOG" 2>&1
    set -x
    echo "SELinux context: $(cat /proc/self/attr/current 2>/dev/null)"
    echo "UID: $(id)"
    echo "PATH: $PATH"
    echo "resetprop_phh location: $(which resetprop_phh 2>/dev/null)"
else
    # Can't write log -- run silently rather than aborting
    LOG=""
fi

# --- Bluetooth: Enable sysbta (system-side Bluetooth audio) ---
# Without this, A2DP audio doesn't work because Sony's vendor BT HAL
# can't open A2DP streams on GSI.
#
# resetprop_phh bypasses init's property service, so vndk.rc's
# "on property:" triggers never fire. We must call phh-prop-handler.sh
# directly to set up the sysbta audio routing and restart audioserver.
resetprop_phh persist.bluetooth.system_audio_hal.enabled true
resetprop_phh persist.bluetooth.avrcpversion avrcp16
resetprop_phh persist.bluetooth.disableinbandringing false
resetprop_phh persist.bluetooth.bqr.event_mask 295006
resetprop_phh persist.bluetooth.bqr.min_interval_ms 500
resetprop_phh persist.bluetooth.iso_link_quality_report true
resetprop_phh persist.bluetooth.leaudio.bypass_allow_list true
resetprop_phh persist.bluetooth.leaudio.notify.idle.during.call true

# Trigger phh-prop-handler.sh to set companion properties:
#   persist.bluetooth.bluetooth_audio_hal.disabled=false
#   persist.bluetooth.a2dp_offload.disabled=true
#   ro.bluetooth.a2dp_offload.supported=false
# NOTE: Its restartAudio() will fail (ctl.restart blocked by SELinux) -- we
# handle the restart ourselves below after patching the audio policy.
/system/bin/phh-prop-handler.sh persist.bluetooth.system_audio_hal.enabled

# --- Inject sysbta into audio policy ---
# The vendor audio policy routes A2DP through the "primary" module (PAL →
# vendor BT HAL) which cannot stream A2DP on GSI. We:
#   1. Copy each vendor audio policy XML to a writable location
#   2. Remove the A2DP output routes from the primary module
#   3. Add an xi:include for the sysbta audio policy module (software BT encoding)
#   4. Bind-mount the patched XML over the vendor original
#   5. Kill audioserver so init auto-restarts it with the patched config
#
# IMPORTANT: We must patch BOTH the sku-specific config AND the generic fallback.
# On initial boot, audioserver loads the sku_pineapple config. After restart
# (killall), it may fall back to the generic config if vendor audio HAL SKU
# detection doesn't re-initialize. We do NOT kill vendor.audio-hal-aidl-service
# to preserve SKU detection.
#
# This is the same bind-mount pattern rw-system.sh uses for Motorola Liber.
# The sysbta module XML is inlined directly rather than using xi:include because:
# - /vendor is read-only (can't copy sysbta config there)
# - audioserver can't read /system/etc/ files (system_file SELinux context)
# - xi:include to /data/ paths also fails (wrong SELinux context)
# Inlining avoids all cross-partition and SELinux issues.
SYSBTA_MODULE='        <!-- sysbta: System-side Bluetooth Audio (injected by pdx245 fixup) -->\
        <module name="sysbta" halVersion="2.0">\
            <mixPorts>\
                <mixPort name="a2dp output" role="source"\/>\
                <mixPort name="hearing aid output" role="source">\
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"\
                             samplingRates="24000 16000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"\/>\
                <\/mixPort>\
            <\/mixPorts>\
            <devicePorts>\
                <devicePort tagName="BT A2DP Out" type="AUDIO_DEVICE_OUT_BLUETOOTH_A2DP" role="sink">\
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"\
                             samplingRates="44100 48000 88200 96000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"\/>\
                <\/devicePort>\
                <devicePort tagName="BT A2DP Headphones" type="AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_HEADPHONES" role="sink">\
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"\
                             samplingRates="44100 48000 88200 96000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"\/>\
                <\/devicePort>\
                <devicePort tagName="BT A2DP Speaker" type="AUDIO_DEVICE_OUT_BLUETOOTH_A2DP_SPEAKER" role="sink">\
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"\
                             samplingRates="44100 48000 88200 96000"\
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"\/>\
                <\/devicePort>\
                <devicePort tagName="BT Hearing Aid Out" type="AUDIO_DEVICE_OUT_HEARING_AID" role="sink"\/>\
            <\/devicePorts>\
            <routes>\
                <route type="mix" sink="BT A2DP Out"\
                       sources="a2dp output"\/>\
                <route type="mix" sink="BT A2DP Headphones"\
                       sources="a2dp output"\/>\
                <route type="mix" sink="BT A2DP Speaker"\
                       sources="a2dp output"\/>\
                <route type="mix" sink="BT Hearing Aid Out"\
                       sources="hearing aid output"\/>\
            <\/routes>\
        <\/module>'

patch_audio_policy() {
    local SRC="$1"
    local DST="$2"

    if [ ! -f "$SRC" ]; then
        echo "  skip: $SRC not found"
        return 1
    fi

    cp "$SRC" "$DST"

    # Remove A2DP output routes from primary module (each route spans 2 lines)
    # This prevents audio routing through PAL → vendor BT HAL (which fails on GSI)
    sed -i '/<route type="mix" sink="BT A2DP Out"/{N;d;}' "$DST"
    sed -i '/<route type="mix" sink="BT A2DP Headphones"/{N;d;}' "$DST"
    sed -i '/<route type="mix" sink="BT A2DP Speaker"/{N;d;}' "$DST"

    # Also remove A2DP device port declarations from primary module so there's
    # no conflict with sysbta's own device port declarations
    sed -i '/<devicePort tagName="BT A2DP Out"/{
        :a; N; /<\/devicePort>/!ba; d
    }' "$DST"
    sed -i '/<devicePort tagName="BT A2DP Headphones"/{
        :a; N; /<\/devicePort>/!ba; d
    }' "$DST"
    sed -i '/<devicePort tagName="BT A2DP Speaker"/{
        :a; N; /<\/devicePort>/!ba; d
    }' "$DST"

    # Inline the full sysbta module before </modules>
    sed -i "/<\/modules>/i\\${SYSBTA_MODULE}" "$DST"

    # Fix permissions: audioserver runs as audioserver user, not root.
    chmod 644 "$DST"

    # Bind-mount patched config over vendor original
    mount -o bind "$DST" "$SRC"
    chcon u:object_r:vendor_configs_file:s0 "$SRC" 2>/dev/null

    echo "  patched: $SRC ($(wc -c < "$DST") bytes, perms $(stat -c %a "$DST"))"
    return 0
}

echo "Patching audio policy configs for sysbta..."

# 1. SKU-specific config (used on initial boot)
patch_audio_policy \
    "/vendor/etc/audio/sku_pineapple/audio_policy_configuration.xml" \
    "/data/local/tmp/audio_policy_sysbta_sku.xml"

# 2. Generic fallback config (used after audioserver restart)
patch_audio_policy \
    "/vendor/etc/audio_policy_configuration.xml" \
    "/data/local/tmp/audio_policy_sysbta_generic.xml"

echo "Audio policy patching complete"

# Kill ONLY audioserver so init restarts it with the patched config.
# Do NOT kill vendor.audio-hal-aidl-service -- that breaks SKU detection
# and causes audioserver to fall back to the generic config.
sleep 1
killall audioserver 2>/dev/null || true
echo "Audioserver killed (init will auto-restart with sysbta)"

# --- Telephony: Enable IMS overlay APK loading ---
# The stock ims.apk has an overlay manifest that requires this property to be
# set before package manager scans. Without it, the APK is ignored:
#   "overlay ignored due to required system property: ro.boot.vendor.qspa.modem"
# Also set at build time in pdx245.mk, but resetprop here ensures it persists.
resetprop_phh ro.boot.vendor.qspa.modem enabled

# --- WiFi 6GHz / WiFi 7 Country Lists ---
# ro.vendor.* namespace is restricted to vendor partition by SELinux.
# These are needed by Sony's WiFi HAL to enable 6E/7 band scanning.
resetprop_phh ro.vendor.sony.wlan.6e_cc_list "US,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,GB,CH,IS,MY,TH,TW,SG,MO"
resetprop_phh ro.vendor.sony.wlan.11be_cc_list "US,HK,JP,AT,BE,BG,HR,CY,CZ,DK,EE,FI,FR,DE,GR,HU,IE,IT,LV,LI,LT,LU,MT,NL,NO,PL,PT,RO,SK,SI,ES,SE,GB,CH,IS,TH,TW,SG,MO,MY"

# --- Restore correct Security Patch Level ---
# rw-system.sh overwrites ro.build.version.security_patch with the vendor SPL
# (ro.vendor.build.security_patch). This is wrong for a Treble GSI -- the system
# and vendor SPLs should be reported independently.
#
# Read the original platform SPL from system build.prop (before rw-system.sh
# overwrote it) and restore it. This way both values display correctly in
# Settings without hardcoding dates.
#
# THREE properties must be updated:
#   1. ro.build.version.security_patch      - the real AOSP property
#   2. persist.sys.pihooks_SECURITY_PATCH   - Evolution X / Play Integrity hooks
#      override; Settings UI reads THIS instead of #1
#   3. ro.build.version.security_patch_orig - some frameworks cache the original
PLATFORM_SPL=$(grep -m1 'ro.build.version.security_patch=' /system/build.prop 2>/dev/null | cut -d= -f2)
if [ -n "$PLATFORM_SPL" ]; then
    resetprop_phh ro.build.version.security_patch "$PLATFORM_SPL"
    # EvoX PIHooks overrides what Settings displays -- must match platform SPL
    resetprop_phh persist.sys.pihooks_SECURITY_PATCH "$PLATFORM_SPL"
fi

echo "=== pdx245-fixup-props.sh completed at $(date) ==="
echo "=== Verification ==="
echo "BT sysbta: $(getprop persist.bluetooth.system_audio_hal.enabled)"
echo "BT offload disabled: $(getprop persist.bluetooth.a2dp_offload.disabled)"
echo "BT audio HAL disabled: $(getprop persist.bluetooth.bluetooth_audio_hal.disabled)"
echo "A2DP offload supported: $(getprop ro.bluetooth.a2dp_offload.supported)"
echo "WiFi 6E: $(getprop ro.vendor.sony.wlan.6e_cc_list | head -c 20)..."
echo "SPL (real): $(getprop ro.build.version.security_patch)"
echo "SPL (pihooks): $(getprop persist.sys.pihooks_SECURITY_PATCH)"
echo "Modem: $(getprop ro.boot.vendor.qspa.modem)"
# Check if sysbta was inlined into audio policy configs
for f in /data/local/tmp/audio_policy_sysbta_sku.xml /data/local/tmp/audio_policy_sysbta_generic.xml; do
    if [ -f "$f" ]; then
        cnt=$(grep -c 'name="sysbta"' "$f" 2>/dev/null)
        echo "Audio policy ($f): sysbta module present=$cnt"
    fi
done

# Make log readable from adb shell (script runs as root, file gets 0600 by default)
if [ -n "$LOG" ]; then
    chmod 644 "$LOG" 2>/dev/null
fi
