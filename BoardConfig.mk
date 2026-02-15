# Inherit from generic arm64 board config
include build/make/target/board/generic_arm64/BoardConfig.mk

# Inherit PHH treble board base
include device/phh/treble/board-base.mk

# Device specific board config
TARGET_BOARD_PLATFORM := kalama
TARGET_BOOTLOADER_BOARD_NAME := pdx245

# Override GSI system_ext prop to remove ro.adb.secure=0 (we want secure ADB)
# BoardConfigGsiCommon.mk (included via generic_arm64) sets this to
# gsi_system_ext.prop which forces insecure ADB. Our custom version keeps all
# other GSI properties but lets vendor/lineage set ro.adb.secure=1.
TARGET_SYSTEM_EXT_PROP := device/sony/pdx245/system_ext.prop

# GSI-specific settings
TARGET_NO_KERNEL_OVERRIDE := true
TARGET_NO_KERNEL_IMAGE := true
TARGET_BOOT_ANIMATION_RES := 1080

# Build overrides for GSI compatibility
SELINUX_IGNORE_NEVERALLOWS := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BOARD_EXT4_SHARE_DUP_BLOCKS := true

# Allow missing dependencies
ALLOW_MISSING_DEPENDENCIES := true

# SELinux Policy Extensions
# BOARD_SEPOLICY_DIRS = vendor partition policy (not useful for GSI since we
# don't modify vendor). Kept for bluetooth property access compatibility.
# SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS = system_ext partition policy (compiled into
# our system image). Used for telephony HAL access rules.
BOARD_SEPOLICY_DIRS += device/sony/pdx245/sepolicy
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += device/sony/pdx245/sepolicy_system_ext
