#!/usr/bin/env bash

set -e
set -u
set -o pipefail

is_app_installed() {
	type "$1" &>/dev/null
}

REPODIR="$(
	cd "$(dirname "$0")"
	pwd -P
)"
cd "$REPODIR"

if ! is_app_installed tmux; then
	printf "WARNING: \"tmux\" command is not found. \
Install it first\n"
	exit 1
fi

if [ ! -e "$HOME/.tmux/plugins/tpm" ]; then
	printf "WARNING: Cannot found TPM (Tmux Plugin Manager) \
 at default location: \$HOME/.tmux/plugins/tpm.\n"
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [ -e "$HOME/.config/tmux/tmux.conf" ]; then
	printf "Found existing tmux.conf in your \$HOME directory. Will create a backup at $HOME/.config/tmux/tmux.conf.bak\n"
fi

# Check if .config/tmux directory exists, if not create it
if [ ! -d "$HOME/.config/tmux" ]; then
	printf "Creating $HOME/.config/tmux directory\n"
	mkdir -p "$HOME/.config/tmux"
fi

# Make backup of original config and copy new one
cp -f "$HOME/.config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf.bak" 2>/dev/null || true
cp tmux.conf "$HOME"/.config/tmux/

# Install TPM plugins.
# TPM requires running tmux server, as soon as `tmux start-server` does not work
# create dump __noop session in detached mode, and kill it when plugins are installed
printf "Install TPM plugins\n"
tmux new -d -s __noop >/dev/null 2>&1 || true
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME"/.tmux/plugins
"$HOME"/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

# Copy plugins folder from .tmux to .config/tmux if it does not exist in .config/tmux
if [ ! -d "$HOME/.config/tmux/plugins" ]; then
	printf "Creating $HOME/.config/tmux/plugins directory\n"
	cp -r "$HOME"/.tmux/plugins "$HOME"/.config/tmux/
fi

printf "OK: Completed\n"
