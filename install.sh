#!/usr/bin/env bash
# fastfetch-cards installer
#   ./install.sh              install the script + arts for the current user
#   ./install.sh --uninstall  remove them (restores a backed-up previous script)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
ART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/art"
TARGET="$BIN_DIR/fastfetch"
MARK="FASTFETCH_CARDS_ART_DIR"   # string that identifies our script

say()  { printf '\033[36m✦\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*" >&2; }

if [[ "${1:-}" == "--uninstall" ]]; then
    if [[ -f "$TARGET" ]] && grep -q "$MARK" "$TARGET"; then
        rm -f "$TARGET"; say "removed $TARGET"
        if [[ -f "$TARGET.bak" ]]; then mv "$TARGET.bak" "$TARGET"; say "restored previous $TARGET"; fi
    fi
    for f in "$SRC"/art/*.txt; do rm -f "$ART_DIR/$(basename "$f")"; done
    rmdir "$ART_DIR" 2>/dev/null || true
    say "uninstalled"
    exit 0
fi

command -v python3 >/dev/null || { warn "python3 is required"; exit 1; }

mkdir -p "$BIN_DIR" "$ART_DIR"
if [[ -e "$TARGET" ]] && ! grep -q "$MARK" "$TARGET" 2>/dev/null; then
    mv "$TARGET" "$TARGET.bak"; warn "existing $TARGET moved to $TARGET.bak"
fi
install -m 755 "$SRC/fastfetch" "$TARGET"
install -m 644 "$SRC"/art/*.txt "$ART_DIR/"
say "script -> $TARGET"
say "arts   -> $ART_DIR ($(ls "$SRC"/art/*.txt | wc -l) files)"

# The wrapper must come before the real fastfetch in PATH.
first="$(PATH="$PATH" command -v fastfetch || true)"
if [[ "$first" != "$TARGET" ]]; then
    warn "$BIN_DIR is not first in PATH (fastfetch resolves to: ${first:-nothing})."
    warn "add to your shell rc:  export PATH=\"$BIN_DIR:\$PATH\""
fi

# Real fastfetch is only needed for passthrough options (-l arch, --help, ...).
real=""
IFS=: read -ra dirs <<< "$PATH"
for d in "${dirs[@]}"; do
    [[ -x "$d/fastfetch" && "$(realpath "$d/fastfetch")" != "$(realpath "$TARGET")" ]] && { real="$d/fastfetch"; break; }
done
[[ -n "$real" ]] || warn "real fastfetch not found: the cards work, but passthrough options (-l <distro>, --help) won't"

command -v lspci >/dev/null || warn "lspci (pciutils) not found: GPU will show as 'Integrated GPU'"
fc-list 2>/dev/null | grep -qi "nerd font" || warn "no Nerd Font found: icons need one (e.g. JetBrainsMono Nerd Font)"

say "done — run: fastfetch   (fastfetch -a saturn, fastfetch --list-arts)"
