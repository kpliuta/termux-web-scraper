#!/bin/sh
#
# This script installs and optionally upgrades the necessary dependencies for Termux.
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

UPGRADE=false

# --- Help message ---

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "This script installs and optionally upgrades the necessary dependencies for Termux."
    echo
    echo "Options:"
    echo "  -u, --upgrade    Upgrade termux packages (default: false)."
    echo "  -h, --help       Show this help message."
}

# --- Argument parsing ---

while [ "$#" -gt 0 ]; do
    case $1 in
        -u|--upgrade) UPGRADE=true ;;
        -h|--help) show_help; exit 0 ;;
        "") ;;  # ignore empty string arguments
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# --- Main Execution ---

# Install dependencies without manual intervention.
export DEBIAN_FRONTEND=noninteractive

TERMUX_MIN_VERSION="0.118.3"

if [ "$UPGRADE" = true ]; then
    # pkg update / pkg upgrade brakes Google Play version of Termux at the moment,
    # but works well the F-Droid version which is > 0.118.3.
    if [ "$(printf '%s\n' "$TERMUX_MIN_VERSION" "$TERMUX_VERSION" | sort -V | head -n1)" = "$TERMUX_MIN_VERSION" ]; then
        echo "Detected F-Droid version (>= $TERMUX_MIN_VERSION), proceeding with package update/upgrade..."

        echo "Updating Termux package lists..."
        apt-get update -y

        echo "Upgrading installed Termux packages..."
        apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef"
        apt-get autoremove -y
    else
        echo "Detected Google Play version (< $TERMUX_MIN_VERSION), skipping package update/upgrade to avoid breakage..."
    fi
fi

# List of the basic required packages.
DEPENDENCIES="proot-distro util-linux uuid-utils"

echo "Checking and installing dependencies..."

# Install dependencies if they are not installed yet.
for pkg in $DEPENDENCIES; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        apt-get install -y "$pkg"
    fi
done

echo "Termux dependencies are up to date."
