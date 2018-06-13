#!/bin/bash

# Make sure we are in the same directory of this file
cd "${0%/*}"
# Include some travis utility function
source "functions.sh"

BRANCH="$1"

set -xe

# Prepare the repository
travis_fold start "flatpak_prepare"
    [[ -d repo ]] || ostree init --mode=archive-z2 --repo=repo
    [[ -d repo/refs/remotes ]] || mkdir -p repo/refs/remotes && touch repo/refs/remotes/.gitkeep
travis_fold end "flatpak_prepare"


# Install runtime and sdk
travis_fold start "flatpak_install_deps"
    travis_time_start
        flatpak --user remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak --user install flathub org.gnome.Platform//3.28 org.gnome.Sdk//3.28
    travis_time_finish
travis_fold end "flatpak_install_deps"

# Build
travis_fold start "flatpak_build"
    travis_time_start
        flatpak-builder --verbose --force-clean --ccache --require-changes --repo=repo \
                        --subject="Nightly build of LinuxShowPlayer, `date`" \
                        build com.github.FrancescoCeruti.LinuxShowPlayer.json
    travis_time_finish
travis_fold end "flatpak_build"

# Update the repository
travis_fold start "flatpak_update_repo"
    travis_time_start
        flatpak build-update-repo --prune --prune-depth=20 --generate-static-deltas repo
        echo 'gpg-verify-summary=false' >> repo/config
    travis_time_finish
travis_fold end "flatpak_update_repo"

set +xe