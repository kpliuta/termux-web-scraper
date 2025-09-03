#!/bin/sh
#
# This script performs the initial, one-time setup for the VNC server.
# It runs non-interactively, setting a default password and creating the
# necessary configuration files.
#
# This setup is only performed once. If an existing configuration is
# detected, the script will exit.
#
# Dependencies:
#   - A VNC server implementation (e.g., tightvncserver) that provides the 'vncpasswd' command.
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Dependency Check ---

# Validate that vncpasswd is installed and executable.
if ! command -v vncpasswd >/dev/null 2>&1; then
  echo "Error: 'vncpasswd' command not found." >&2
  echo "Please install a VNC server (e.g., tightvncserver) and ensure it's in your PATH." >&2
  exit 1
fi

# --- Configuration ---

# Define VNC configuration directory.
VNC_DIR="$HOME/.vnc"

# The existence of the password file is our indicator that setup has been run before.
if [ -f "$VNC_DIR/passwd" ]; then
  echo "VNC server appears to be already configured. Skipping setup."
  exit 0
fi

# --- Main Execution ---

echo "Performing first-time VNC server setup..."

# Create the VNC configuration directory.
mkdir -p "$VNC_DIR"
echo "  - Created directory: $VNC_DIR"

# Set a default VNC password non-interactively.
# The default password is "termux".
DEFAULT_PASS="termux"
VNC_PASSWD_FILE="$VNC_DIR/passwd"

echo "  - Setting default VNC password to '${DEFAULT_PASS}'..."
echo "$DEFAULT_PASS" | vncpasswd -f > "$VNC_PASSWD_FILE"
chmod 600 "$VNC_PASSWD_FILE"

# Create the xstartup file to launch the XFCE desktop environment.
XSTARTUP_FILE="$VNC_DIR/xstartup"
echo "  - Creating xstartup file: $XSTARTUP_FILE"
cat << EOF > "$XSTARTUP_FILE"
#!/bin/sh

# Start the XFCE desktop environment.
startxfce4 &
EOF

# Make the xstartup script executable.
chmod +x "$XSTARTUP_FILE"

echo "VNC server setup completed successfully."
