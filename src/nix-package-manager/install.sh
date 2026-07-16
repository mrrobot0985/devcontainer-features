#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
MULTI_USER="${NIXPACKAGEMANAGERMULTIUSER:-true}"
FLAKES="${NIXPACKAGEMANAGERFLAKES:-true}"
HOME_MANAGER="${NIXPACKAGEMANAGERHOMEMANAGER:-false}"
PACKAGES="${NIXPACKAGEMANAGERPACKAGES:-}"

# Detect username
if [ "$USERNAME" = "auto" ] || [ "$USERNAME" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 '{ if ($3 >= val) exit; print $1 }' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "$CURRENT_USER" > /dev/null 2>&1; then
            USERNAME="$CURRENT_USER"
            break
        fi
    done
    if [ -z "$USERNAME" ]; then
        USERNAME="root"
    fi
fi

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

# Determine installer flags
INSTALL_FLAGS=""
if [ "$MULTI_USER" = "true" ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --daemon"
else
    INSTALL_FLAGS="$INSTALL_FLAGS --no-daemon"
fi

# Install Nix using the official installer
echo "Installing Nix package manager..."
if ! command -v nix >/dev/null 2>&1; then
    # Download and run the official installer
    curl -L https://nixos.org/nix/install | sh -s -- $INSTALL_FLAGS
else
    echo "Nix is already installed. Skipping installation."
fi

# Ensure Nix is available in the current shell
if [ -f /etc/profile.d/nix.sh ]; then
    # shellcheck source=/dev/null
    . /etc/profile.d/nix.sh
elif [ -f "$USER_HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck source=/dev/null
    . "$USER_HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Enable flakes if requested
if [ "$FLAKES" = "true" ]; then
    NIX_CONFIG_FILE="/etc/nix/nix.conf"
    if [ -d /etc/nix ]; then
        if ! grep -q "experimental-features.*flakes" "$NIX_CONFIG_FILE" 2>/dev/null; then
            mkdir -p /etc/nix
            echo "experimental-features = nix-command flakes" >> "$NIX_CONFIG_FILE"
            echo "Flakes enabled in $NIX_CONFIG_FILE"
        fi
    else
        # Single-user mode may not have /etc/nix
        USER_NIX_CONFIG="${USER_HOME}/.config/nix/nix.conf"
        mkdir -p "$(dirname "$USER_NIX_CONFIG")"
        if ! grep -q "experimental-features.*flakes" "$USER_NIX_CONFIG" 2>/dev/null; then
            echo "experimental-features = nix-command flakes" >> "$USER_NIX_CONFIG"
            echo "Flakes enabled in $USER_NIX_CONFIG"
        fi
    fi
fi

# Install home-manager if requested
if [ "$HOME_MANAGER" = "true" ]; then
    echo "Installing home-manager..."
    if command -v nix-channel >/dev/null 2>&1; then
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        # Install home-manager
        nix-shell '<home-manager>' -A install 2>/dev/null || echo "home-manager install may require manual step after container start"
    else
        echo "WARNING: nix-channel not available; home-manager installation deferred."
        echo "         Run 'nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager'"
        echo "         and 'nix-channel --update' after container startup."
    fi
fi

# Install requested packages
if [ -n "$PACKAGES" ]; then
    echo "Installing Nix packages: $PACKAGES"
    if command -v nix-env >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        nix-env -iA nixpkgs.{${PACKAGES// /,}} 2>/dev/null || echo "WARNING: Some packages may not exist in nixpkgs. Install manually with nix-env -iA nixpkgs.<package>"
    else
        echo "WARNING: nix-env not available; cannot install packages at build time."
        echo "         Packages '$PACKAGES' will need to be installed manually."
    fi
fi

# Add Nix to shell profiles for the user
for PROFILE in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    if [ -f "$PROFILE" ]; then
        if ! grep -q "/etc/profile.d/nix.sh" "$PROFILE" 2>/dev/null; then
            echo 'if [ -e /etc/profile.d/nix.sh ]; then . /etc/profile.d/nix.sh; fi' >> "$PROFILE"
        fi
        if ! grep -q "\.nix-profile/etc/profile.d/nix.sh" "$PROFILE" 2>/dev/null; then
            echo 'if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi' >> "$PROFILE"
        fi
    fi
done

echo "Nix Package Manager installed."
echo "  Flakes: $FLAKES"
echo "  Home Manager: $HOME_MANAGER"
if [ -n "$PACKAGES" ]; then
    echo "  Requested packages: $PACKAGES"
fi
