#!/bin/sh

# Make sure we are in the same directory of this file
cd "${0%/*}"
BRANCH="$1"

set -xe

# Prepare repository
[[ -d repo ]] || ostree init --mode=archive-z2 --repo=repo
[[ -d repo/refs/remotes ]] || mkdir -p repo/refs/remotes && touch repo/refs/remotes/.gitkeep

# Install runtime and sdk
flatpak --user remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install flathub org.gnome.Platform//3.28 org.gnome.Sdk//3.28

# Build
flatpak-builder --verbose --force-clean --ccache --require-changes --repo=repo \
                --subject="Nightly build of LinuxShowPlayer, `date`" \
                build com.github.FrancescoCeruti.LinuxShowPlayer.json

# Update the repository
flatpak build-update-repo --prune --prune-depth=20 --generate-static-deltas repo
echo 'gpg-verify-summary=false' >> repo/config

set +xe