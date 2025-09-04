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
#   ./run_distro.sh -s session-id -d /path/to/your/work-dir -f your_scenario.py -o /path/to/your/output/dir [options]
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

SESSION_ID=""
WORK_DIR=""
SCENARIO_FILE=""
OUTPUT_DIR=""
UPGRADE=false

# --- Help message ---

show_help() {
    echo "Usage: $0 -s <session-id> -d <work-dir> -f <scenario-file> -o <output-dir> [options]"
    echo
    echo "This script is intended to be run from within the proot-distro container."
    echo
    echo "Required Arguments:"
    echo "  -s, --session-id id        Scraper session ID."
    echo "  -d, --work-dir dir         Path to a mounted poetry project repository containing selenium scenarios."
    echo "  -f, --scenario-file file   Relative path to a Python selenium scenario file within the specified work-dir."
    echo "  -o, --output-dir dir       Path to the mounted directory where scraper output will be saved."
    echo
    echo "Options:"
    echo "  -u, --upgrade              Upgrade container packages (default: false)."
    echo "  -h, --help                 Show this help message."
}

# --- Argument parsing and validation ---

while [ "$#" -gt 0 ]; do
    case $1 in
        -s|--session-id) SESSION_ID="$2"; shift ;;
        -d|--work-dir) WORK_DIR="$2"; shift ;;
        -f|--scenario-file) SCENARIO_FILE="$2"; shift ;;
        -o|--output-dir) OUTPUT_DIR="$2"; shift ;;
        -u|--upgrade) UPGRADE=true ;;
        -h|--help) show_help; exit 0 ;;
        "") ;;  # ignore empty string arguments
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
if [ -z "$SESSION_ID" ] || [ -z "$WORK_DIR" ] || [ -z "$SCENARIO_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

# Validate work directory.
if [ ! -d "$WORK_DIR" ] || [ ! -f "$WORK_DIR/pyproject.toml" ]; then
    echo "Error: Scenarios directory '$SCENARIOS_DIR' is not a valid Poetry project."
    exit 1
fi

# Validate scenario file.
SCENARIO_FILE_PATH="$WORK_DIR/$SCENARIO_FILE"
if [ ! -f "$SCENARIO_FILE_PATH" ] || [ "${SCENARIO_FILE##*.}" != "py" ]; then
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

# Change to the work directory so poetry can find its virtual environment.
cd "$WORK_DIR"

# Install Python dependencies defined in pyproject.toml.
echo "Installing Python dependencies with Poetry..."
poetry install

# Export the session ID as an environment variable so the python script can access it.
export SCRAPER_SESSION_ID="$SESSION_ID"
echo "Session ID set to: $SCRAPER_SESSION_ID"

# Export the output directory path as an environment variable so the python script can access it.
export SCRAPER_OUTPUT_DIR="$OUTPUT_DIR"
echo "Output directory set to: $SCRAPER_OUTPUT_DIR"

# Set up a trap to ensure VNC is terminated and environment variables are cleaned up when the script exits for any reason.
trap 'echo "Terminating VNC server..."; \
      "$DISTRO_SCRIPTS_DIR/terminate_vnc.sh"; \
      unset SCRAPER_SESSION_ID; \
      unset SCRAPER_OUTPUT_DIR' EXIT

echo "Starting VNC server..."
"$DISTRO_SCRIPTS_DIR/run_vnc.sh"

# Execute the python script using poetry.
echo "Executing scenario script: $SCENARIO_FILE"
poetry run python "$SCENARIO_FILE"

echo "Distro script finished."
