#!/bin/bash

# Exit if something fails during the build
set -e

echo -e "\n\n"
echo "================= build_flatpak.sh ================="
echo -e "\n"

# Make sure we are in the same directory of this file
cd "${0%/*}"

export FLATPAK_RUNTIME="org.gnome.Platform//3.32 org.gnome.Sdk//3.32"
export FLATPAK_PY_VERSION="3.7"
export FLATPAK_PY_IGNORE_PACKAGES="setuptools six pygobject pycairo"

echo "FLATPAK_RUNTIME = "$FLATPAK_RUNTIME
echo "FLATPAK_PY_VERSION = "$FLATPAK_PY_VERSION

export FLATPAK_APP_ID="com.github.FrancescoCeruti.LinuxShowPlayer"
export FLATPAK_APP_MODULE="linux-show-player"

echo "FLATPAK_APP_ID = " $FLATPAK_APP_ID
echo "FLATPAK_APP_MODULE = " $FLATPAK_APP_MODULE

echo -e "\n"
echo "#################################"
echo "#    Install runtime and sdk    #"
echo "#################################"
echo -e "\n"

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --assumeyes $FLATPAK_RUNTIME

echo -e "\n"
echo "#######################################"
echo "#    Generate the flatpak manifest    #"
echo "#######################################"
echo -e "\n"

python3 prepare_flatpak.py

echo -e "\n"
echo "###########################"
echo "#    Build the flatpak    #"
echo "###########################"
echo -e "\n"

# Prepare the repository
ostree init --mode=archive-z2 --repo=repo
# Build the flatpak
flatpak-builder --verbose --force-clean --ccache --repo=repo build $FLATPAK_APP_ID.json

echo -e "\n"
echo "##########################"
echo "#    Bundle the build    #"
echo "##########################"
echo -e "\n"

mkdir -p out
# Create the bundle (without blocking the script)
flatpak build-bundle repo out/LinuxShowPlayer.flatpak $FLATPAK_APP_ID $BUILD_BRANCH &
# pid of the last command
pid=$!
# Elapsed time
elapsed="00:00"
# If this script is killed, kill the 'build-bundle' process
trap "kill $pid 2> /dev/null" EXIT
# While the bundle is running print the elapsed time every second
while kill -0 $pid 2> /dev/null; do
    elapsed=$(echo -en $(ps -o etime= -p "$pid"))
    echo -ne "[ $elapsed ] Building ...\r"
    sleep 1
done
echo "Completed in $elapsed                                  "
# Disable the trap on a normal exit.
trap - EXIT

echo -e "\n"
echo "================= build_flatpak.sh ================="
echo -e "\n\n"

set +e