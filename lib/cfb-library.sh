#!/usr/bin/env bash
# clipboad-file-bridge.lib
# shared helper functions for cfb-copy / cfb-cut / cfb-paste.
# sourced by each script, never run directly.

cfb_header() {
	printf " \\ CFB \\  Clipboard File Bridge v1.0\n"
	printf "          😃 by Mario Lohajner 2026\n"
	printf "\n"
}

cfb_clipboard_write() {
	# writes the x-special/gnome-copied-files payload to the clipboard
	local payload="$1"
	if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
		printf '%s' "$payload" | wl-copy -t x-special/gnome-copied-files
	elif command -v xclip >/dev/null 2>&1; then
		printf '%s' "$payload" | xclip -selection clipboard -t x-special/gnome-copied-files
	else
		echo "CFB: requires 'xclip' (X11) or 'wl-clipboard' (Wayland)" >&2
		return 1
	fi
}

cfb_clipboard_read() {
	# prints the raw x-special/gnome-copied-files payload, or nothing if empty/unsupported
	if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
		wl-paste -t x-special/gnome-copied-files 2>/dev/null
	elif command -v xclip >/dev/null 2>&1; then
		xclip -selection clipboard -t x-special/gnome-copied-files -o 2>/dev/null
	fi
}

cfb_clipboard_clear() {
	if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
		wl-copy --clear
	elif command -v xclip >/dev/null 2>&1; then
		printf '' | xclip -selection clipboard
	fi
}

cfb_urlencode() {
	# percent-encodes a path for safe use inside a file:// URI.
	# processes byte-by-byte (LC_ALL=C) so multi-byte UTF-8 characters
	# (accented letters etc.) are encoded correctly, one byte at a time.
	local LC_ALL=C
	local string="$1"
	local length="${#string}"
	local i c hex
	local encoded=""

	for ((i = 0; i < length; i++)); do
		c="${string:i:1}"
		case "$c" in
			[a-zA-Z0-9.~_-] | /)
				encoded+="$c"
				;;
			*)
				printf -v hex '%02X' "'$c"
				encoded+="%$hex"
				;;
		esac
	done

	printf '%s' "$encoded"
}

cfb_urldecode() {
	# decodes a file:// URI into a plain filesystem path
	local uri="$1"
	uri="${uri#file://}"
	printf '%b' "${uri//%/\\x}"
}

cfb_mark() {
	# shared logic for cfb-copy and cfb-cut
	local mode="$1"
	shift

	local first="${1:-}"
	if [ $# -eq 0 ] || [ "$first" = "-h" ] || [ "$first" = "--help" ]; then
		cfb_header >&2
		echo "usage: cfb-$mode file1 [file2 ...]" >&2
		if [ "$first" = "-h" ] || [ "$first" = "--help" ]; then
			return 0
		fi
		return 1
	fi

	local f
	for f in "$@"; do
		if [ ! -e "$f" ]; then
			echo "cfb-$mode: '$f': no such file" >&2
			return 1
		fi
	done

	local abspaths=()
	for f in "$@"; do
		abspaths+=("$(readlink -f -- "$f")")
	done

	local uri_list=""
	local i
	for ((i = 0; i < ${#abspaths[@]}; i++)); do
		if [ "$i" -gt 0 ]; then
			uri_list+=$'\n'
		fi
		uri_list+="file://$(cfb_urlencode "${abspaths[$i]}")"
	done

	local payload="$mode"$'\n'"$uri_list"
	cfb_clipboard_write "$payload" || return 1
}
