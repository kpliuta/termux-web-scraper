# Termux Web Scraper

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A robust and flexible web scraping framework designed to run on Android devices using Termux. It leverages a `proot-distro` Ubuntu container to create a powerful and isolated scraping environment, enabling you to run complex Selenium-based web scraping tasks on your Android device.

[The Droid You're Looking For: Scraping Websites on Android with Termux](https://kpliuta.github.io/blog/posts/scraping-websites-on-android-with-termux/)

## Features

*   **Run Selenium on Android:** Execute web scraping scripts using Selenium and Firefox within a Termux environment.
*   **Isolated Environment:** Utilizes a `proot-distro` Ubuntu container to provide a clean and isolated environment for your scraping tasks.
*   **Headed Operation:** Runs Firefox in a headed mode using a VNC server, allowing the execution of complex scenarios while bypassing headless browser detection.
*   **Flexible and Extensible:** The framework is designed to be modular and extensible, allowing you to easily add your own scraping logic, error handling, and notification mechanisms.
*   **Continuous Operation:** The `run.sh` script supports a loop mode, allowing you to run your scrapers continuously at a specified interval.
*   **Easy to Use:** The framework provides a simple and intuitive builder pattern for creating and configuring your scrapers.

## How it Works

The Termux Web Scraper works by setting up a complete web scraping environment on your Android device. Here's a high-level overview of the architecture:

```
+-------------------------------------------------+
|                  Android Device                 |
| +---------------------------------------------+ |
| |                    Termux                   | |
| | +-----------------------------------------+ | |
| | |           proot-distro (Ubuntu)         | | |
| | | +-------------------------------------+ | | |
| | | |             VNC Server              | | | |
| | | +-------------------------------------+ | | |
| | | |               Firefox               | | | |
| | | +-------------------------------------+ | | |
| | | |           Python Framework          | | | |
| | | | (Selenium, ScraperBuilder, etc.)    | | | |
| | | +-------------------------------------+ | | |
| | | |          Your Scraper Script        | | | |
| | | +-------------------------------------+ | | |
| | +-----------------------------------------+ | |
| +---------------------------------------------+ |
+-------------------------------------------------+
```

1.  **Termux Environment:** The main `run.sh` script is executed in the Termux environment. It handles the initial setup, argument parsing, and environment validation.
2.  **`proot-distro` Ubuntu Container:** The script then installs and launches an Ubuntu container using `proot-distro`. This provides a full-fledged Linux environment for running the scraper.
3.  **VNC Server:** Inside the container, a VNC server is started to provide a virtual display for Firefox.
4.  **Firefox and Selenium:** Firefox is launched in the virtual display, and Selenium is used to control the browser and perform the web scraping tasks.
5.  **Python Framework:** The Python framework provides a high-level API for building and running your scrapers. It includes a `ScraperBuilder` for configuring your scraper, as well as error handling and notification mechanisms.
6.  **Your Scraper Script:** You provide a Python script that defines the scraping logic using the provided framework.

## Prerequisites

Before you can use the Termux Web Scraper, you need to have the following installed on your Android device:

*   **Termux:** You can download Termux from the [F-Droid](https://f-droid.org/en/packages/com.termux/) or [Google Play](https://play.google.com/store/apps/details?id=com.termux) store.
*   **Git:** You can install Git in Termux by running `pkg install git`.

You also need to:

*   **Disable Battery Optimization:** Disable battery optimization for Termux to prevent it from being killed by the Android system.
*   **Acquire a Wakelock:** Acquire a wakelock in Termux to prevent the device from sleeping while your scraper is running.
*   **Address Phantom Process Killing (Android 12+):** On Android 12 and newer, you may need to disable phantom process killing to prevent Termux from being killed. You can do this by running the following command in an ADB shell:
    ```bash
    ./adb shell "settings put global settings_enable_monitor_phantom_procs false"
    ```

## Project Structure

```
.
├── scripts
│   ├── distro
│   │   ├── ...
│   ├── termux
│   │   └── ...
│   └── run.sh
└── termux_web_scraper
    ├── error_hook.py
    ├── helpers.py
    ├── notifier.py
    ├── scraper_builder.py
    └── scraper_runner.py
```

*   **`scripts`:** Contains the shell scripts for setting up and running the scraper.
    *   **`distro`:** Scripts that are run inside the `proot-distro` Ubuntu container.
    *   **`termux`:** Scripts that are run in the Termux environment.
    *   **`run.sh`:** The main entry point for the scraper.
*   **`termux_web_scraper`:** The Python framework for building and running your scrapers.
    *   **`scraper_builder.py`:** Provides a `ScraperBuilder` class for configuring your scraper.
    *   **`scraper_runner.py`:** The core scraper class that runs the web scraping steps.
    *   **`error_hook.py`:** Defines error handling mechanisms.
    *   **`notifier.py`:** Defines notification mechanisms.
    *   **`helpers.py`:** Provides helper functions for interacting with web pages.

## Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/termux-web-scraper.git
    ```

2.  **Navigate to the Project Directory:**
    ```bash
    cd termux-web-scraper
    ```

3.  **Run the Scraper:**
    ```bash
    ./scripts/run.sh -d /path/to/your/work-dir -f your_scenario.py
    ```

## Usage

The `run.sh` script is the main entry point for the web scraper. Here's a detailed explanation of its arguments:

*   `-d, --work-dir`: **(Required)** Path to a Poetry project repository containing your Selenium scenarios.
*   `-f, --scenario-file`: **(Required)** Relative path to a Python Selenium scenario file within the specified work-dir.
*   `-u, --upgrade`: Upgrade Termux and container packages (default: `false`).
*   `-l, --loop`: Execute the scraper in a continuous loop (default: `false`).
*   `-t, --loop-timeout`: Set the timeout in seconds between loop iterations. Requires the `--loop` argument (default: `300` seconds).
*   `-i, --loop-error-ignore`: Ignore errors that occur during loop iterations (default: `false`).
*   `-o, --output-dir`: Specifies a local directory path on the host Android device to bind to a directory inside the container. This allows files, such as screenshots and scraped data, to be transferred from the container to the local device. The default binding is `/sdcard/termux-web-scraper` (local) to `/mnt/scraper/out` (container).
*   `-h, --help`: Show the help message.

## Integrating the Python Framework

To use the Python framework, first, add the following dependency to the `[tool.poetry.dependencies]` section of your `pyproject.toml` file, specifying the desired version:

```toml
[tool.poetry.dependencies]
termux-web-scraper = { git = "https://github.com/kpliuta/termux-web-scraper.git", rev = "VERSION" }
```

Next, install the new dependency by running the poetry install command:

```bash
poetry install
```

Once installed, you can use the `ScraperBuilder` to create and run a scraper, as shown in the simple example below:

```python
from termux_web_scraper.scraper_builder import ScraperBuilder
from termux_web_scraper.notifier import TelegramNotifier
from termux_web_scraper.error_hook import ScreenshotErrorHook, NotificationErrorHook
from termux_web_scraper.helpers import click_element, send_keys

# Define a scraping step
def login(driver, state, notify):
    send_keys(driver, ("id", "username"), "user")
    send_keys(driver, ("id", "password"), "pass")
    click_element(driver, ("id", "login-button"))
    notify("Logged in successfully!")

# Build the scraper
scraper = (
    ScraperBuilder()
    .with_step("Login", login)
    .with_notifier(TelegramNotifier("YOUR_BOT_TOKEN", "YOUR_CHAT_ID"))
    .with_error_hook(ScreenshotErrorHook("./screenshots"))
    .with_error_hook(NotificationErrorHook())
    .build()
)

# Run the scraper
scraper.run()
```

## Usage Examples and Projects

*   **Example Project:** For a practical demonstration of the framework's capabilities, see the [termux-web-scraper-example](https://github.com/kpliuta/termux-web-scraper-example.git) repository.
*   **Active Projects:** This framework is actively used in the these projects:
    * [sinotrack-alert-monitor](https://github.com/kpliuta/sinotrack-alert-monitor.git)
    * [cita-previa-extranjeria-monitor](https://github.com/kpliuta/cita-previa-extranjeria-monitor)

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue if you have any suggestions or find any bugs.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
