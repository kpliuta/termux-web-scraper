#!/bin/sh
#
# This script installs and optionally upgrades the necessary dependencies for Termux.
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

UPGRADE=false

# --- Argument parsing ---

# Check for the optional upgrade flag.
if [ "$1" = "-u" ]; then
    UPGRADE=true
fi

# --- Main Execution ---

echo "Updating Termux package lists..."
# The -y flag automatically answers yes to prompts.
pkg update -y

if [ "$UPGRADE" = true ]; then
    echo "Upgrading installed Termux packages..."
    pkg upgrade -y
fi

echo "Installing core Termux dependencies..."
# proot-distro is essential for managing the container environment.
pkg install -y proot-distro

echo "Termux dependencies are up to date."
