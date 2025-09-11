#!/bin/sh
#
# This script starts a VNC server (e.g., tightvncserver).
#
# Dependencies:
#   - A VNC server implementation (e.g., tightvncserver) that provides the 'vncserver' command.
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
  echo "Please install a VNC server (e.g., tightvncserver) and ensure it's in your PATH." >&2
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

DISPLAY_NUM="${DISPLAY#:}" # Extracts the number, e.g., ":1" -> "1"

# Clean up stale lock files from previous crashed sessions.
LOCK_FILE_X="/tmp/.X${DISPLAY_NUM}-lock"
LOCK_FILE_X11="/tmp/.X11-unix/X${DISPLAY_NUM}"

# FIX: In some cases, VNC creates lock files that are not detectable by neither if [ -e "$FILE" ],
# nor if [ -L "$FILE" ]. The script attempts to remove the specified items and provides a notification upon success.

# Example of a problematic lock file:
#   lrwxrwxrwx. 1 root root 100 Sep 1 12:00 /tmp/.X1-lock -> /.l2s/.l2s..tX1-lock0001
rm "$LOCK_FILE_X" 2>/dev/null && echo "  - Removing ${LOCK_FILE_X} lock file..."
rm "$LOCK_FILE_X11" 2>/dev/null && echo "  - Removing ${LOCK_FILE_X11} lock file..."

# Clean up stale PID and log files from previous crashed sessions.
PID_FILE="$HOME/.vnc/$(hostname)${DISPLAY}.pid"
if [ -f "$PID_FILE" ]; then
    echo "  - Removing stale PID file: ${PID_FILE}..."
    rm -f "$PID_FILE"
fi

LOG_FILE="$HOME/.vnc/$(hostname)${DISPLAY}.log"
if [ -f "$LOG_FILE" ]; then
    echo "  - Removing stale log file: ${LOG_FILE}..."
    rm -f "$LOG_FILE"
fi

# Start the VNC server process.
echo "Starting VNC server..."
echo "  - Display:  ${DISPLAY}"
echo "  - Geometry: ${GEOMETRY}"

vncserver "${DISPLAY}" -geometry "${GEOMETRY}"

# Graceful Awaiting.
echo "Waiting for VNC server to start..."

# It can take a few seconds for the VNC server to create the PID file.
# We will wait for a maximum of 10 seconds for the PID file to appear.
ATTEMPTS=0
MAX_ATTEMPTS=20 # 20 * 0.5s = 10s

while [ ! -f "$PID_FILE" ] && [ "$ATTEMPTS" -lt "$MAX_ATTEMPTS" ]; do
    sleep 0.5
    ATTEMPTS=$((ATTEMPTS + 1))
done

if [ ! -f "$PID_FILE" ]; then
    echo "Error: VNC server failed to start. PID file not found after 10 seconds." >&2
    if [ -f "$LOG_FILE" ]; then
        echo "--- VNC Log ---" >&2
        cat "$LOG_FILE" >&2
        echo "--- End VNC Log ---" >&2
    fi
    exit 1
fi

# Additionally, check if the process is actually running
VNC_PID=$(cat "$PID_FILE")
if ! ps -p "$VNC_PID" > /dev/null; then
    echo "Error: VNC server process with PID $VNC_PID is not running." >&2
    if [ -f "$LOG_FILE" ]; then
        echo "--- VNC Log ---" >&2
        cat "$LOG_FILE" >&2
        echo "--- End VNC Log ---" >&2
    fi
    exit 1
fi

echo "VNC server started successfully."
