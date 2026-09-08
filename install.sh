#!/usr/bin/env bash
# install.sh
# installs Clipboard File Bridge (cfb-copy / cfb-cut / cfb-paste) from the bin/ and
# lib/ directories next to this script into ~/.local/{bin,lib}, and adds
# the @c/@x/@p aliases to ~/.bashrc if they aren't already there.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
src_bin="$script_dir/bin"
src_lib="$script_dir/lib"

dest_bin="$HOME/.local/bin"
dest_lib="$HOME/.local/lib"

marker="# --- cfb opertors (@c/@x/@p) ---"

if [ ! -d "$src_bin" ] || [ ! -d "$src_lib" ]; then
	echo "install.sh: expected 'bin/' and 'lib/' next to this script" >&2
	exit 1
fi

# --- check for a clipboard backend ------------------------------------

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
	if ! command -v wl-copy >/dev/null 2>&1; then
		echo "Warning: Wayland session detected but 'wl-clipboard' is not installed." >&2
		echo "  Install it with: sudo apt install wl-clipboard" >&2
	fi
else
	if ! command -v xclip >/dev/null 2>&1; then
		echo "Warning: X11 session detected but 'xclip' is not installed." >&2
		echo "  Install it with: sudo apt install xclip" >&2
	fi
fi

# --- copy files ---------------------------------------------------------

mkdir -p "$dest_bin" "$dest_lib"
cp -f "$src_lib/"* "$dest_lib/"
cp -f "$src_bin/"* "$dest_bin/"
chmod +x "$dest_bin/cfb-copy" "$dest_bin/cfb-cut" "$dest_bin/cfb-paste"

echo "Copied cfb-copy, cfb-cut, cfb-paste to $dest_bin"
echo "Copied cfb-library.sh to $dest_lib"

# --- wire up ~/.bashrc, only once ----------------------------------------

bashrc="$HOME/.bashrc"

if [ -f "$bashrc" ] && grep -qF "$marker" "$bashrc"; then
	echo "~/.bashrc already configured, skipping."
else
	{
		echo ""
		echo "$marker"
		if [[ ":$PATH:" != *":$dest_bin:"* ]]; then
			echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
		fi
		echo "alias @c='cfb-copy'"
		echo "alias @x='cfb-cut'"
		echo "alias @p='cfb-paste'"
	} >> "$bashrc"
	echo "Added PATH and @c/@x/@p aliases to $bashrc"
fi

echo ""
echo "Done. Run: source ~/.bashrc   (or open a new terminal)"
