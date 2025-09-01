#!/bin/sh
#
# This script terminates a running VNC server session.
#
# Dependencies:
#   - A VNC server implementation (e.g., TigerVNC) that provides the 'vncserver' command.
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

# --- Session Check ---

echo "Checking for active VNC session on display ${DISPLAY}..."
# Use `vncserver -list` and `grep` to check if a session for the current display exists.
# The `grep -w` ensures an exact match (e.g., :1 won't match :10).
if ! vncserver -list | grep -q -w "${DISPLAY}"; then
  echo "Error: No VNC server is running on display ${DISPLAY}." >&2
  exit 1
fi

# --- Main Execution ---

echo "Terminating VNC server on display ${DISPLAY}..."

vncserver -kill "${DISPLAY}"

echo "VNC server on display ${DISPLAY} terminated successfully."
