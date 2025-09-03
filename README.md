# termux-web-scraper

## TODO

- uses firefox as a browser to exec scenario

Prerequisites:
- termux installed (google play or f-droid version, no matter)
- git installed in termux (pkg install git)
- turn off battery optimization for termux
- Address Android 12+ Phantom Process Killing (https://ivonblog.com/en-us/posts/fix-termux-signal9-error/)
        # For Android 13+
        ./adb shell "settings put global settings_enable_monitor_phantom_procs false"


How to run:
- launch termux and acquire a wakelock 
- checkout the client repo (e.g. https://github.com/kpliuta/termux-web-scraper-example.git)
- run script
