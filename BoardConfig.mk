# Inherit from generic arm64 board config
include build/make/target/board/generic_arm64/BoardConfig.mk

# Inherit PHH treble board base
include device/phh/treble/board-base.mk

# Device specific board config
TARGET_BOARD_PLATFORM := kalama
TARGET_BOOTLOADER_BOARD_NAME := pdx245

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
