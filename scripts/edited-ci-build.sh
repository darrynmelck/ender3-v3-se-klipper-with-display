#!/bin/bash
# Build setup script for continuous integration testing.

set -eux

MAIN_DIR="${PWD}"
BUILD_DIR="${PWD}/ci_build"
CACHE_DIR="${PWD}/ci_cache"

mkdir -p "${BUILD_DIR}" "${CACHE_DIR}"

######################################################################
# Install system dependencies
######################################################################

echo -e "\n\n=============== Install system dependencies\n\n"

PKGS="virtualenv libffi-dev build-essential"
PKGS="${PKGS} gcc-avr avr-libc"
PKGS="${PKGS} libnewlib-arm-none-eabi gcc-arm-none-eabi binutils-arm-none-eabi"
PKGS="${PKGS} pv libmpfr-dev libgmp-dev libmpc-dev texinfo bison flex"

sudo apt-get update
sudo apt-get -y install ${PKGS}

######################################################################
# Install (or build) PRU GCC
######################################################################

echo -e "\n\n=============== Install embedded PRU GCC\n\n"

PRU_FILE="${CACHE_DIR}/gnupru.tar.gz"
PRU_DIR="${BUILD_DIR}/pru-gcc"

if [ ! -f "${PRU_FILE}" ]; then
    cd "${BUILD_DIR}"

    git config --global user.email "you@example.com"
    git config --global user.name "GitHub Actions"

    git clone https://github.com/dinuxbg/gnupru -b 2024.05 --depth 1

    cd gnupru
    export PREFIX="${PRU_DIR}"

    ./download-and-prepare.sh 2>&1 | pv -nli 30 > "${BUILD_DIR}/gnupru-build.log"
    ./build.sh 2>&1 | pv -nli 30 >> "${BUILD_DIR}/gnupru-build.log"

    cd "${BUILD_DIR}"
    tar cfz "${PRU_FILE}" pru-gcc/
else
    cd "${BUILD_DIR}"
    tar xfz "${PRU_FILE}"
fi

######################################################################
# Skip or1k-linux-musl-cross
#
# The current edited-ci-build.sh only builds the STM32 target.
# It does not need the OpenRISC cross-compiler.
######################################################################

echo "Skipping unused or1k-linux-musl-cross toolchain."

######################################################################
# Create Python 3 virtual environment
######################################################################

echo -e "\n\n=============== Install Python 3 virtualenv\n\n"

cd "${MAIN_DIR}"

virtualenv -p python3 "${BUILD_DIR}/python-env"

"${BUILD_DIR}/python-env/bin/pip" install \
    -r "${MAIN_DIR}/scripts/klippy-requirements.txt"
