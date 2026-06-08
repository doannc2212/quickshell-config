#!/usr/bin/env sh
# Generate a quickshell "wallpaper" theme from an image, using matugen or wallust.
#
# It only writes the palette to wallpaper-theme.json — it does NOT switch the
# shell into wallpaper mode. quickshell live-reloads the file and, if you're in
# wallpaper mode, repaints instantly.
#
# To both regenerate the palette AND switch into wallpaper mode, call the IPC
# instead, which runs this script for you:
#     qs ipc call theme wallpaper <image>
#
# This script is the lower-level entry point if you only want to refresh the
# palette without changing mode (e.g. a wallpaper-daemon hook). For awws:
#     [daemon]
#     on_change = "~/.config/quickshell/theme-switcher/wallpaper-theme/set.sh %w"
#
# Force a specific tool with WALLPAPER_THEME_TOOL=matugen|wallust (default: auto).
set -eu

img=${1:-}
[ -n "$img" ] || { echo "set.sh: usage: set.sh <image>" >&2; exit 1; }
[ -f "$img" ] || { echo "set.sh: no such image: $img" >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tool=${WALLPAPER_THEME_TOOL:-auto}

run_matugen() { matugen image "$img" -c "$dir/matugen/config.toml" -m dark --prefer saturation -q; }
run_wallust() { wallust run "$img" -d "$dir/wallust" -s -q; }

case "$tool" in
  matugen) run_matugen ;;
  wallust) run_wallust ;;
  auto)
    if command -v matugen >/dev/null 2>&1; then run_matugen
    elif command -v wallust >/dev/null 2>&1; then run_wallust
    else echo "set.sh: need matugen or wallust installed" >&2; exit 1
    fi ;;
  *) echo "set.sh: unknown WALLPAPER_THEME_TOOL=$tool" >&2; exit 1 ;;
esac
