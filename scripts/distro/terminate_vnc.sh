#!/bin/sh
#
# This script terminates a running VNC server session.
#
# Dependencies:
#   - A VNC server implementation (e.g., tightvncserver) that provides the 'vncserver' command.
#
# Usage:
#   export DISPLAY=:1
#   ./terminate_vnc.sh
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

# --- Session Check ---

echo "Checking for active VNC session on display ${DISPLAY}..."

# Construct the path to the VNC PID file.
PID_FILE="$HOME/.vnc/$(hostname)${DISPLAY}.pid"

# Check if the PID file exists to determine if a session is active.
if ! [ -f "$PID_FILE" ]; then
  echo "Error: No VNC server is running on display ${DISPLAY}." >&2
  exit 1
fi

# --- Main Execution ---

echo "Terminating VNC server on display ${DISPLAY}..."

# Get the PID before killing the server.
VNC_PID=$(cat "$PID_FILE")

# The -kill command can fail if the process is already dead but the PID file is stale.
# We'll ignore errors here (`set +e`) and verify termination gracefully later.
set +e
vncserver -kill "${DISPLAY}"
set -e

# Graceful Shutdown.
echo "Waiting for VNC server to terminate..."

ATTEMPTS=0
MAX_ATTEMPTS=20 # 20 * 0.5s = 10s

# Wait for the PID file to be removed.
while [ -f "$PID_FILE" ] && [ "$ATTEMPTS" -lt "$MAX_ATTEMPTS" ]; do
    sleep 0.5
    ATTEMPTS=$((ATTEMPTS + 1))
done

# If the PID file still exists, the graceful shutdown failed.
if [ -f "$PID_FILE" ]; then
    echo "Warning: VNC server did not terminate gracefully. PID file still exists." >&2
    echo "Attempting to forcefully kill process $VNC_PID..." >&2
    kill -9 "$VNC_PID" 2>/dev/null
    sleep 1 # Give it a moment to die.
fi

# Double-check if the process is still running.
if ps -p "$VNC_PID" > /dev/null 2>/dev/null; then
    echo "Warning: VNC process $VNC_PID is still running. Forcefully killing..." >&2
    kill -9 "$VNC_PID" 2>/dev/null
fi

echo "VNC server on display ${DISPLAY} terminated successfully."
