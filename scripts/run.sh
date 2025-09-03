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
#   ./scripts/run.sh -s /path/to/your/scenarios -f your_script.py [options]
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Default values ---

SCENARIOS_DIR=""
SCRIPT=""
UPGRADE=false
LOOP=false
LOOP_TIMEOUT=300 # 5 minutes
LOOP_ERROR_IGNORE=false
OUTPUT_DIR="/sdcard/termux-web-scraper"
MNT_OUTPUT_DIR="/mnt/scraper/out"

# --- Help message ---

show_help() {
    echo "Usage: $0 -s <scenarios-dir> -f <script> [options]"
    echo
    echo "Required Arguments:"
    echo "  -s, --scenarios-dir dir           Path to a poetry repo with selenium scenarios."
    echo "  -f, --script x                    Path to a python selenium scenario in the scenarios-dir."
    echo
    echo "Options:"
    echo "  -u, --upgrade                     Upgrade termux packages as well as container packages (default: false)."
    echo "  -l, --loop                        Execute scraper in a loop (default: false)."
    echo "  -t, --loop-timeout x              Used with a loop. Timeout in seconds between loop iterations (default: 300 (5 minutes))."
    echo "  -i, --loop-error-ignore           Ignore errors during loop iterations (default: false)."
    echo "  -d, --output-dir local:container  Specifies a local directory (on the Android device) to bind a directory inside the"
    echo "                                    container. This is used to get files (e.g., screenshots, scraped data) out of the container."
    echo "                                    (default: /sdcard/termux-web-scraper:/mnt/scraper/out)"
    echo "  -h, --help                        Show this help message."
}

# --- Argument parsing and validation ---

while [ "$#" -gt 0 ]; do
    case $1 in
        -u|--upgrade) UPGRADE=true ;;
        -l|--loop) LOOP=true ;;
        -t|--loop-timeout) LOOP_TIMEOUT="$2"; shift ;;
        -i|--loop-error-ignore) LOOP_ERROR_IGNORE=true ;;
        -s|--scenarios-dir) SCENARIOS_DIR="$2"; shift ;;
        -f|--script) SCRIPT="$2"; shift ;;
        -d|--output-dir)
            OUTPUT_DIR_RAW="$2"
            OUTPUT_DIR="${OUTPUT_DIR_RAW%%:*}"
            MNT_OUTPUT_DIR="${OUTPUT_DIR_RAW#*:}"
            shift
            ;;
        -h|--help) show_help; exit 0 ;;
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
if [ -z "$SCENARIOS_DIR" ] || [ -z "$SCRIPT" ]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

# Validate scenarios directory.
if [ ! -d "$SCENARIOS_DIR" ] || [ ! -f "$SCENARIOS_DIR/pyproject.toml" ]; then
    echo "Error: Scenarios directory '$SCENARIOS_DIR' is not a valid Poetry project."
    exit 1
fi
SCENARIOS_DIR=$(realpath "$SCENARIOS_DIR")

# Validate script file.
SCRIPT_PATH="$SCENARIOS_DIR/$SCRIPT"
if [ ! -f "$SCRIPT_PATH" ] || [ "${SCRIPT##*.}" != "py" ]; then
    echo "Error: Script file '$SCRIPT_PATH' does not exist or is not a Python script."
    exit 1
fi

# --- Configuration ---

SCRIPTS_DIR=$(realpath "$(dirname "$0")")
DISTRO_SCRIPTS_DIR="$SCRIPTS_DIR/distro"
TERMUX_SCRIPTS_DIR="$SCRIPTS_DIR/termux"

MNT_SCRAPER="/mnt/scraper"
MNT_DISTRO_SCRIPTS_DIR="$MNT_SCRAPER/scripts"
MNT_SCENARIOS_DIR="$MNT_SCRAPER/scenarios"

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
        --bind "$SCENARIOS_DIR:$MNT_SCENARIOS_DIR" \
        --bind "$OUTPUT_DIR:$MNT_OUTPUT_DIR" \
        --no-sysvipc -- \
        "$MNT_DISTRO_SCRIPTS_DIR/run_distro.sh" \
        $upgrade_arg \
        -s "$MNT_SCENARIOS_DIR" \
        -f "$SCRIPT" \
        -d "$MNT_OUTPUT_DIR"
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
