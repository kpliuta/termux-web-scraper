# TODO
# this is a single entrance point for the scraper
# arguments
# - upgrade (-u): packages (system, proot_distro)
# - loop (-l): execute scraper in a loop (boolean, default false)
# - looptimeout (-t): used with a loop. Default 5 min

# add arguments handling and descriptive help

# check if it is run from the termux env, exit with a descriptive message if not

# install termux dependencies (install_dependencies.sh)

# chroot into linux dist, mount work folder (script/distro scripts to run inside the distro + python scripts)
# and run proot_distro entrance point (run_distro.sh)