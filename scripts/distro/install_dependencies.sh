#!/bin/sh
#
# This script installs and optionally upgrades the necessary dependencies for the distro container.
# It ensures that packages are not reinstalled if they already exist.
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

UPGRADE=false

# --- Help message ---

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "This script installs and optionally upgrades the necessary dependencies for the distro container."
    echo
    echo "Options:"
    echo "  -u, --upgrade    Upgrade container packages (default: false)."
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
    echo "Updating container package lists..."
    apt-get update -y

    echo "Upgrading installed container packages..."
    apt-get upgrade -y
    apt-get autoremove -y
fi

# List of the basic required packages from the official Ubuntu Linux repository.
DEPENDENCIES="wget xfce4 dbus-x11 tightvncserver firefox firefox-geckodriver python3-poetry"

echo "Checking and installing dependencies..."

# TODO: ensure all required dependencies are installed without user interaction (layout configuration, etc.).
# Install dependencies if they are not installed yet.
for pkg in $DEPENDENCIES; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        apt-get install -y "$pkg"
    fi
done

# TODO: move scenario dependent dependencies to children repos.
# ffmpeg is a dependency for selenium RecaptchaSolver.
if ! dpkg -s ffmpeg >/dev/null 2>&1; then
    echo "Installing ffmpeg..."
    apt-get install -y ffmpeg
fi

echo "Distro dependencies are up to date."
