#!/bin/sh
# Headless Ketho/LuaLS diagnostics on the PC (release gate in AGENTS.md).
# Needs LuaLS 3.19.1 in ~/.cache/fgt-luals/luals and Ketho's PACKAGED
# extension (0.22.3, 3,506 annotation files) in ~/.cache/fgt-luals/ketho-ext;
# the GitHub repo alone has only ~500 annotation files. Config:
# reports/checks/luals-2026-10-12-config.json (adjust its library path).
C="$HOME/.cache/fgt-luals"
cd "$C" && rm -rf log meta-cache && "$C/luals/bin/lua-language-server.exe" \
  --check "$(cd "$(dirname "$0")/.." && pwd -W)" --configpath "$C/luals-config.json" \
  --logpath "$C/log" --metapath "$C/meta-cache" --check_out_path "$C/diag.json"
echo "annotation load events: $(cat "$C"/log/file_*.log | grep -c ketho-ext)"
