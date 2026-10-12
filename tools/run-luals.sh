#!/bin/sh
# Headless Ketho/LuaLS diagnostics on the PC (release gate in AGENTS.md).
# Needs LuaLS 3.19.1 in ~/.cache/fgt-luals/luals and Ketho's PACKAGED
# extension (0.22.3, 3,506 annotation files) in ~/.cache/fgt-luals/ketho-ext;
# the GitHub repo alone has only ~500 annotation files. Config:
# reports/checks/luals-2026-10-12-config.json (adjust its library path) copied
# to ~/.cache/fgt-luals/luals-config.json. Fails if the annotations don't load.
ADDON="$(cd "$(dirname "$0")/.." && pwd -W)" || exit 2
C="$HOME/.cache/fgt-luals"
cd "$C" && rm -rf log meta-cache || exit 2
"$C/luals/bin/lua-language-server.exe" --check "$ADDON" --configpath "$C/luals-config.json" \
  --logpath "$C/log" --metapath "$C/meta-cache" --check_out_path "$C/diag.json" 2>&1 | tr '\r' '\n' | grep -E "Diagnosis|problem"
N=$(cat "$C"/log/file_*.log 2>/dev/null | grep -c ketho-ext)
echo "addon: $ADDON"
echo "annotation load events: $N (expect ~14028)"
[ "$N" -gt 1000 ] || { echo "FAILED: annotations did not load or nothing was checked"; exit 1; }
