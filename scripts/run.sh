#!/bin/sh
#
# This script is the entry point for the web scraper.
# It is designed to be executed from the Android's Termux emulator.
#
# The script performs the following actions:
#   1. Parses command-line arguments.
#   2. Validates the environment (Termux) and arguments.
#   3. Installs necessary Termux packages.
#   4. Installs and configures a Ubuntu Linux proot-distro if not already present.
#   5. Runs the web scraping scenario within the Ubuntu Linux container, mounting necessary directories.
#   6. Can run the scraper in a continuous loop with a configurable timeout.
#
# Usage:
#   ./scripts/run.sh -d /path/to/your/work-dir -f your_scenario.py [options]
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

WORK_DIR=""
SCENARIO_FILE=""
UPGRADE=false
LOOP=false
LOOP_TIMEOUT=300 # 5 minutes
LOOP_ERROR_IGNORE=false
OUTPUT_DIR="/sdcard/termux-web-scraper"
MNT_OUTPUT_DIR="/mnt/scraper/out"

# --- Help message ---

show_help() {
    echo "Usage: $0 -d <work-dir> -f <scenario-file> [options]"
    echo
    echo "Required Arguments:"
    echo "  -d, --work-dir dir                Path to a poetry project repository containing selenium scenarios."
    echo "  -f, --scenario-file file          Relative path to a Python selenium scenario file within the specified work-dir."
    echo
    echo "Options:"
    echo "  -u, --upgrade                     Upgrade Termux and container packages (default: false)."
    echo "  -l, --loop                        Execute the scraper in a continuous loop (default: false)."
    echo "  -t, --loop-timeout x              Set the timeout in seconds between loop iterations."
    echo "                                    Requires the --loop argument (default: 300 (5 minutes))."
    echo "  -i, --loop-error-ignore           Ignore errors that occur during loop iterations (default: false)."
    echo "  -o, --output-dir local:container  Specifies a local directory path on the host Android device to bind"
    echo "                                    to a directory inside the container. This binding allows files, such as"
    echo "                                    screenshots and scraped data, to be transferred from the container to the local device."
    echo "                                    The default binding is /sdcard/termux-web-scraper (local) to /mnt/scraper/out (container)."
    echo "  -h, --help                        Show this help message."
}

# --- Argument parsing and validation ---

while [ "$#" -gt 0 ]; do
    case $1 in
        -u|--upgrade) UPGRADE=true ;;
        -l|--loop) LOOP=true ;;
        -t|--loop-timeout) LOOP_TIMEOUT="$2"; shift ;;
        -i|--loop-error-ignore) LOOP_ERROR_IGNORE=true ;;
        -d|--work-dir) WORK_DIR="$2"; shift ;;
        -f|--scenario-file) SCENARIO_FILE="$2"; shift ;;
        -o|--output-dir)
            OUTPUT_DIR_RAW="$2"
            OUTPUT_DIR="${OUTPUT_DIR_RAW%%:*}"
            MNT_OUTPUT_DIR="${OUTPUT_DIR_RAW#*:}"
            shift
            ;;
        -h|--help) show_help; exit 0 ;;
        "") ;;  # ignore empty string arguments
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Check if running in Termux.
if [ -z "$TERMUX_VERSION" ]; then
    echo "Error: This script must be run within the Termux environment."
    exit 1
fi

# Check for required arguments.
if [ -z "$WORK_DIR" ] || [ -z "$SCENARIO_FILE" ]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

# Validate work directory.
if [ ! -d "$WORK_DIR" ] || [ ! -f "$WORK_DIR/pyproject.toml" ]; then
    echo "Error: Scenarios directory '$SCENARIOS_DIR' is not a valid Poetry project."
    exit 1
fi
WORK_DIR=$(realpath "$WORK_DIR")

# Validate scenario file.
SCENARIO_FILE_PATH="$WORK_DIR/$SCENARIO_FILE"
if [ ! -f "$SCENARIO_FILE_PATH" ] || [ "${SCENARIO_FILE##*.}" != "py" ]; then
    echo "Error: Script file '$SCRIPT_PATH' does not exist or is not a Python script."
    exit 1
fi

# --- Configuration ---

SCRIPTS_DIR=$(realpath "$(dirname "$0")")
DISTRO_SCRIPTS_DIR="$SCRIPTS_DIR/distro"
TERMUX_SCRIPTS_DIR="$SCRIPTS_DIR/termux"

MNT_SCRAPER="/mnt/scraper"
MNT_DISTRO_SCRIPTS_DIR="$MNT_SCRAPER/scripts"
MNT_WORK_DIR="$MNT_SCRAPER/workdir"

# Request storage access permission from Termux to be able to write to /sdcard.
if [ ! -d "$HOME/storage/shared" ]; then
    echo "Requesting storage access..."
    termux-setup-storage
fi

# Create output directory if it doesn't exist.
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR" || {
      echo "Error: Could not create output directory '$OUTPUT_DIR'.";
      exit 1;
    }
fi
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

echo "Installing Termux dependencies..."
termux_upgrade_arg=""
if [ "$UPGRADE" = true ]; then
    termux_upgrade_arg="-u"
fi
"$TERMUX_SCRIPTS_DIR/install_dependencies.sh" "$termux_upgrade_arg"

# Install Ubuntu Linux if not present
if ! proot-distro login ubuntu -- true > /dev/null 2>&1; then
    echo "Ubuntu Linux not found. Installing..."
    proot-distro install ubuntu
fi

# --- Main Execution ---

run_scraper() {
    echo "Starting scraper..."
    
    upgrade_arg=""
    if [ "$UPGRADE" = true ]; then
        upgrade_arg="-u"
    fi

    proot-distro login ubuntu \
        --bind "$DISTRO_SCRIPTS_DIR:$MNT_DISTRO_SCRIPTS_DIR" \
        --bind "$WORK_DIR:$MNT_WORK_DIR" \
        --bind "$OUTPUT_DIR:$MNT_OUTPUT_DIR" \
        --no-sysvipc -- \
        "$MNT_DISTRO_SCRIPTS_DIR/run_distro.sh" \
        $upgrade_arg \
        -d "$MNT_WORK_DIR" \
        -f "$SCENARIO_FILE" \
        -o "$MNT_OUTPUT_DIR"
}

if [ "$LOOP" = true ]; then
    echo "Starting loop..."
    while true; do
        if [ "$LOOP_ERROR_IGNORE" = true ]; then
            set +e
            run_scraper
            set -e
        else
            run_scraper
        fi
        echo "Sleeping for $LOOP_TIMEOUT seconds..."
        sleep "$LOOP_TIMEOUT"
        # Pass the upgrade argument to the container only on the first iteration.
        UPGRADE=false
    done
else
    run_scraper
fi

echo "Scraper execution is finished."
