#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$HOME/.config/hypr/custom/general.lua"
START_MARK="-- BEGIN MONITOR LAYOUT"
END_MARK="-- END MONITOR LAYOUT"

DUAL_LAYOUT=$(cat <<'EOF'
-- BEGIN MONITOR LAYOUT
hl.monitor({
    output = "desc:AU Optronics B173HAN04.9",
    mode = "1920x1080@60.015",
    position = "0x0",
    scale = "1",
    transform = 1
})

hl.monitor({
    output = "desc:Microstep MSI MP275Q PC3M265400920",
    mode = "2560x1440@59.951",
    position = "1080x0",
    scale = 1
})
-- END MONITOR LAYOUT
EOF
)

AUTO_LAYOUT=$(cat <<'EOF'
-- BEGIN MONITOR LAYOUT
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1"
})
-- END MONITOR LAYOUT
EOF
)

replace_block() {
  local repl_file="$1"
  local tmp
  tmp="$(mktemp)"
  awk -v start="$START_MARK" -v end="$END_MARK" -v repl_file="$repl_file" '
    BEGIN {
      while ((getline line < repl_file) > 0) {
        repl = repl line "\n"
      }
      close(repl_file)
    }
    {
      if ($0 == start) { printf "%s", repl; inblock=1; next }
      if (inblock) {
        if ($0 == end) { inblock=0 }
        next
      }
      print
    }
    END { if (inblock) exit 1 }
  ' "$CONFIG_FILE" > "$tmp"
  mv "$tmp" "$CONFIG_FILE"
}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Missing config: $CONFIG_FILE" >&2
  exit 1
fi

if ! grep -Fq -- "$START_MARK" "$CONFIG_FILE" || ! grep -Fq -- "$END_MARK" "$CONFIG_FILE"; then
  echo "Missing monitor layout markers in $CONFIG_FILE" >&2
  exit 1
fi

if grep -Fq "desc:Microstep MSI MP275Q PC3M265400920" "$CONFIG_FILE"; then
  new_layout="$AUTO_LAYOUT"
else
  new_layout="$DUAL_LAYOUT"
fi

repl_file="$(mktemp)"
printf "%s\n" "$new_layout" > "$repl_file"
replace_block "$repl_file"
rm -f "$repl_file"

hyprctl reload
