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
        "") ;;  # ignore empty string arguments
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# --- Main Execution ---

# Prevent hangs during installation of elementary-xfce-icon-theme.
# This issue occurs because gtk-update-icon-cache can be extremely slow or hang due to
# how proot handles file system calls and memory.
echo "Applying fix for gtk-update-icon-cache hang..."

# 1. Tell dpkg to move the real binary if it tries to install it.
dpkg-divert --divert /usr/bin/gtk-update-icon-cache.distrib --rename /usr/bin/gtk-update-icon-cache

# 2. Create your dummy version that does nothing.
ln -sf /bin/true /usr/bin/gtk-update-icon-cache

# Install dependencies without manual intervention.
export DEBIAN_FRONTEND=noninteractive

if [ "$UPGRADE" = true ]; then
    echo "Updating container package lists..."
    apt-get update -y

    echo "Upgrading installed container packages..."
    apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef"
    apt-get autoremove -y
fi

# List of the basic required packages from the official Ubuntu Linux repository.
DEPENDENCIES="wget xfce4 dbus-x11 tightvncserver firefox python3-poetry"

echo "Checking and installing dependencies..."

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

echo "Container dependencies are up to date."
