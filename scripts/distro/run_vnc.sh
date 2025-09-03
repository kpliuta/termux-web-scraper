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
if [ -e "$LOCK_FILE_X" ]; then
    echo "  - Removing ${LOCK_FILE_X} lock file..."
    rm -f "$LOCK_FILE_X"
fi

LOCK_FILE_X11="/tmp/.X11-unix/X${DISPLAY_NUM}"
if [ -e "$LOCK_FILE_X11" ]; then
    echo "  - Removing ${LOCK_FILE_X11} lock file..."
    rm -f "$LOCK_FILE_X11"
fi

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

# TODO: deal with 'error: expected absolute path: "--shm-helper"' messages during execution
vncserver "${DISPLAY}" -geometry "${GEOMETRY}"

# TODO: implement graceful awaiting logic instead of sleep here
sleep 10

echo "VNC server started successfully."
