# TODO
# implement this script. Adhere to conventions. See @run_vnc.sh for an example and adhere to it codestyle.
# Make a code clear and readable. Make comments clear and easy. Feel free to make changes to make a code/comments clearer,
# more maintainable and more readable. Print to the output where it's needed to make it clear for a user about what's happening atm.

# this is an entrance point for proot_distro
# arguments
# - upgrade (-u): packages (system, proot_distro)
# - scenarios-dir (-s X): path to a poetry repo with selenium scenarios. Required
# - script (-f X): patch to a selenium scenario script file in the scenarios-dir. Required
# - output-dir (-d): Directory to use to get files (e.g., screenshots, scraped data) out of the container. Required


# add arguments handling and descriptive help

# check if it is run from the proot_distro env, exit with a descriptive message if not

# export DISPLAY env val to be :1

# install distro dependencies (install_dependencies.sh)

# run
# - tbd...