#!/bin/sh
#
# This script starts a VNC server (e.g., TigerVNC or TightVNC).
#
# Dependencies:
#   - A VNC server implementation (e.g., TigerVNC) that provides the 'vncserver' command.
#
# Usage:
#   export DISPLAY=:1
#   export VNC_GEOMETRY="1280x720"  # Optional
#   ./run_vnc.sh
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Dependency Check ---

# Validate that vncserver is installed and executable.
if ! command -v vncserver >/dev/null 2>&1; then
  echo "Error: 'vncserver' command not found." >&2
  echo "Please install a VNC server (e.g., TigerVNC) and ensure it's in your PATH." >&2
  exit 1
fi

# --- Configuration ---

# Validate that the DISPLAY variable is set.
if [ -z "$DISPLAY" ]; then
  echo "Error: DISPLAY environment variable is not set." >&2
  echo "Usage: export DISPLAY=:1" >&2
  exit 1
fi

# Set default geometry if VNC_GEOMETRY is not provided.
DEFAULT_GEOMETRY="1920x1080"
GEOMETRY="${VNC_GEOMETRY:-$DEFAULT_GEOMETRY}"

# --- Main Execution ---

echo "Preparing VNC session..."

# Clean up stale lock files from previous crashed sessions.
DISPLAY_NUM="${DISPLAY#:}" # Extracts the number, e.g., ":1" -> "1"

LOCK_FILE_X="/tmp/.X${DISPLAY_NUM}-lock"
if [ -f "$LOCK_FILE_X" ]; then
    echo "  - Removing ${LOCK_FILE_X} lock file..."
    rm -f "$LOCK_FILE_X"
fi

LOCK_FILE_X11="/tmp/.X11-unix/X${DISPLAY_NUM}"
if [ -f "$LOCK_FILE_X11" ]; then
    echo "  - Removing ${LOCK_FILE_X11} lock file..."
    rm -f "$LOCK_FILE_X11"
fi

# Start the VNC server process.
echo "Starting VNC server..."
echo "  - Display:  ${DISPLAY}"
echo "  - Geometry: ${GEOMETRY}"

vncserver "${DISPLAY}" -geometry "${GEOMETRY}"

# TODO: implement graceful awaiting logic instead of sleep here
sleep 10

echo "VNC server started successfully."
