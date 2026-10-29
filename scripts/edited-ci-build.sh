#!/bin/bash
# Build the Ender-3 V3 SE display-enabled STM32 firmware.

set -euxo pipefail

MAIN_DIR="${PWD}"
BUILD_DIR="${MAIN_DIR}/ci_build"
OUTPUT_DIR="${BUILD_DIR}/output"
TARGET="test/configs/displayv3se.config"

mkdir -p "${OUTPUT_DIR}"

echo "===== Clean previous build ====="
make distclean

echo "===== Load firmware configuration ====="
cp "${TARGET}" .config
make olddefconfig

echo "===== Verify important configuration ====="
grep -E \
  'CONFIG_MACH_STM32F401=|CONFIG_MACH_STM32F103=|CONFIG_CLOCK_FREQ=|CONFIG_FLASH_APPLICATION_ADDRESS=|CONFIG_STM32_FLASH_START_|CONFIG_STM32_CLOCK_REF_|CONFIG_CLOCK_REF_FREQ=|CONFIG_STM32_SERIAL_USART1=|CONFIG_SERIAL_BRIDGE=|CONFIG_ENABLE_SERIAL_BRIDGE_USART2=|CONFIG_WANT_DISPLAYS=' \
  .config | tee "${OUTPUT_DIR}/build-config-check.txt"

echo "===== Check required settings ====="
grep -qx 'CONFIG_MACH_STM32F401=y' .config
! grep -qx 'CONFIG_MACH_STM32F103=y' .config
grep -qx 'CONFIG_SERIAL_BRIDGE=y' .config
grep -qx 'CONFIG_ENABLE_SERIAL_BRIDGE_USART2=y' .config
grep -qx 'CONFIG_WANT_DISPLAYS=y' .config

echo "===== Save resolved configuration ====="
cp .config "${OUTPUT_DIR}/displayv3se.resolved.config"

echo "===== Compile firmware ====="
make V=1

echo "===== Check firmware output ====="
test -s out/klipper.bin
cp out/klipper.bin "${OUTPUT_DIR}/displayv3se.bin"

echo "===== Firmware size and SHA256 ====="
ls -lh "${OUTPUT_DIR}"
sha256sum "${OUTPUT_DIR}/displayv3se.bin"
