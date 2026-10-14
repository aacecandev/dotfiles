#!/usr/bin/env sh
# install.sh — Bootstrap entrypoint.
#   1. Install the bare prerequisites needed to download mise (curl + TLS roots).
#   2. Install mise (rootless) into ~/.local/bin.
#   3. Run `mise bootstrap`, which installs the remaining apt packages
#      (git, zsh, unzip, ...) declared in [bootstrap.packages] plus the dev tools.
# Usage:
#   sh install.sh
#   curl -fsSL <raw-install-url> | sh
set -eu

MISE_BIN="$HOME/.local/bin/mise"

# Directory holding this script and mise.toml.
script_dir="$(cd "$(dirname "$0")" && pwd)"

# mise.run needs curl and CA certificates before mise exists. Everything else
# (git, zsh, unzip) is declared in [bootstrap.packages] and installed by
# `mise bootstrap`, so this only covers the chicken-and-egg prerequisites.
ensure_prereqs() {
    missing=""
    command -v curl >/dev/null 2>&1 || missing="curl"
    [ -f /etc/ssl/certs/ca-certificates.crt ] || missing="$missing ca-certificates"

    # Trim and bail out if nothing is missing.
    missing="$(echo "$missing" | sed 's/^ *//;s/ *$//')"
    [ -n "$missing" ] || { echo "Prerequisites present."; return; }

    if command -v apt-get >/dev/null 2>&1; then
        echo "Installing prerequisites: $missing"
        sudo=""
        [ "$(id -u)" -eq 0 ] || sudo="sudo"
        DEBIAN_FRONTEND=noninteractive $sudo apt-get update
        # shellcheck disable=SC2086
        DEBIAN_FRONTEND=noninteractive $sudo apt-get install -y --no-install-recommends $missing
    else
        echo "WARNING: missing '$missing' but apt-get is unavailable; install them manually." >&2
    fi
}

install_mise() {
    if command -v mise >/dev/null 2>&1 || [ -x "$MISE_BIN" ]; then
        echo "mise already installed."
    else
        echo "Installing mise..."
        curl -fsSL https://mise.run | sh
    fi
    export PATH="$HOME/.local/bin:$PATH"
}

run_bootstrap() {
    cd "$script_dir"
    echo "Trusting mise config..."
    mise trust -y -a
    echo "Running mise bootstrap..."
    mise bootstrap --yes
}

main() {
    ensure_prereqs
    install_mise
    mise --version
    run_bootstrap
}

main "$@"
