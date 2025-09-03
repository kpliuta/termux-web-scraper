#!/bin/sh
#
# This script is the entry point for the scraper inside the proot-distro container.
#
# The script performs the following actions:
#   1. Parses command-line arguments passed from the main script.
#   2. Validates the environment (proot-distro container) and arguments.
#   3. Installs dependencies within the container (system packages and Python project dependencies).
#   4. Starts a VNC server for the browser.
#   5. Executes the specified Python scraper script using Poetry.
#   6. Stops the VNC server upon completion.
#
# Usage:
#   ./run_distro.sh -s /path/to/your/scenarios -f your_script.py -d /path/to/your/output/dir [options]
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

UPGRADE=false
SCENARIOS_DIR=""
SCRIPT=""
OUTPUT_DIR=""

# --- Help message ---

show_help() {
    echo "Usage: $0 -s <scenarios-dir> -f <script> -d <output-dir> [options]"
    echo
    echo "This script is intended to be run from within the proot-distro container."
    echo
    echo "Required Arguments:"
    echo "  -s, --scenarios-dir dir    Path to the mounted poetry repo with selenium scenarios."
    echo "  -f, --script file          Path to the python selenium scenario in the scenarios-dir."
    echo "  -d, --output-dir dir       Path to the mounted directory for scraper output."
    echo
    echo "Options:"
    echo "  -u, --upgrade              Upgrade container packages (default: false)."
    echo "  -h, --help                 Show this help message."
}

# --- Argument parsing and validation ---

while [ "$#" -gt 0 ]; do
    case $1 in
        -u|--upgrade) UPGRADE=true ;;
        -s|--scenarios-dir) SCENARIOS_DIR="$2"; shift ;;
        -f|--script) SCRIPT="$2"; shift ;;
        -d|--output-dir) OUTPUT_DIR="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Check if running in a proot-distro container.
if ! uname -a | grep -q -i "proot-distro"; then
    echo "Error: This script must be run within a proot-distro container."
    exit 1
fi

# Check for required arguments.
if [ -z "$SCENARIOS_DIR" ] || [ -z "$SCRIPT" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

# Validate scenarios directory.
if [ ! -d "$SCENARIOS_DIR" ] || [ ! -f "$SCENARIOS_DIR/pyproject.toml" ]; then
    echo "Error: Scenarios directory '$SCENARIOS_DIR' is not a valid Poetry project."
    exit 1
fi

# Validate script file.
SCRIPT_PATH="$SCENARIOS_DIR/$SCRIPT"
if [ ! -f "$SCRIPT_PATH" ] || [ "${SCRIPT##*.}" != "py" ]; then
    echo "Error: Script file '$SCRIPT_PATH' does not exist or is not a Python script."
    exit 1
fi

# Validate output directory.
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory '$OUTPUT_DIR' does not exist. It should be mounted into the container."
    exit 1
fi

# --- Configuration ---

DISTRO_SCRIPTS_DIR=$(realpath "$(dirname "$0")")

# Set the DISPLAY variable for GUI applications to connect to the VNC server.
export DISPLAY=:1
echo "DISPLAY set to $DISPLAY"

echo "Installing container dependencies..."
upgrade_arg=""
if [ "$UPGRADE" = true ]; then
    upgrade_arg="-u"
fi
"$DISTRO_SCRIPTS_DIR/install_dependencies.sh" "$upgrade_arg"

echo "Setting up VNC server..."
"$DISTRO_SCRIPTS_DIR/setup_vnc.sh"

# --- Main Execution ---

# Change to the scenarios directory so poetry can find its virtual environment.
cd "$SCENARIOS_DIR"

# Install Python dependencies defined in pyproject.toml.
echo "Installing Python dependencies with Poetry..."
poetry install

# Export the output directory path as an environment variable so the python script can access it.
export SCRAPER_OUTPUT_DIR="$OUTPUT_DIR"
echo "Output directory set to: $SCRAPER_OUTPUT_DIR"

# Set up a trap to ensure VNC is terminated when the script exits for any reason.
trap 'echo "Terminating VNC server..."; "$DISTRO_SCRIPTS_DIR/terminate_vnc.sh"' EXIT

echo "Starting VNC server..."
"$DISTRO_SCRIPTS_DIR/run_vnc.sh"

# Execute the python script using poetry.
echo "Executing scenario script: $SCRIPT"
poetry run python "$SCRIPT"

echo "Distro script finished."
