# termux-web-scraper

## TODO

- uses firefox as a browser to exec scenario

Prerequisites:
- termux installed (google play or f-droid version, no matter)
- turn off battery optimization for termux
- ??? android security rights for not killing long-running processes
- git installed in termux (pkg install git)
- Address Android 12+ Phantom Process Killing (https://ivonblog.com/en-us/posts/fix-termux-signal9-error/)
        # For Android 13+
        ./adb shell "settings put global settings_enable_monitor_phantom_procs false"


How to run:
- checkout the repo
- run script
- allow termux run in the background
- acquire wakelock 
