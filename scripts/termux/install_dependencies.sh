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
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# --- Main Execution ---

if [ "$UPGRADE" = true ]; then
    echo "Updating Termux package lists..."
    pkg update -y

    echo "Upgrading installed Termux packages..."
    pkg upgrade -y
fi

if ! pkg list-installed | grep -q "^proot-distro/"; then
    echo "Installing proot-distro..."
    pkg install -y proot-distro
fi

echo "Termux dependencies are up to date."
