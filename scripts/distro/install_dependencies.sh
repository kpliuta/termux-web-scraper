# TODO
# arguments
# - upgrade (-u): upgrade container packages (default: false)

# add arguments handling and descriptive help

# upgrade packages if upgrade argument is set
#  apt-get update -y
#  apt-get upgrade -y
#  apt-get autoremove -y

# install dependencies (if it's not installed yet):
#  apt-get install -y wget
#  apt-get install -y xfce4
#  apt-get install -y dbus-x11
#  apt-get install -y tightvncserver
#  apt-get install -y firefox
#  apt-get install -y firefox-geckodriver
#  apt-get install -y ffmpeg     # dependency for selenium RecaptchaSolver
#  apt-get install -y python3-poetry