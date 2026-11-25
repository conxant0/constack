#!/usr/bin/env bash
# install.sh [--replace]: link constack into ~/.claude, so a `git pull` here updates it.
#   skills/<name>, statusline.js, hooks/<file>  -> symlinks into this checkout
#   CLAUDE.md                                   -> your ~/.claude/CLAUDE.md imports ours (@<path>), so your own rules stay
#   settings.json                               -> copied from settings.example.json when missing, else merge by hand
# A path that already exists and is not our link is left alone and reported (exit 1). --replace moves each one to
# ~/.claude/backups/constack-<time>/ first, then links.
set -u
src=$(cd "$(dirname "$0")" && pwd); dst=$HOME/.claude
replace=0; [ "${1:-}" = --replace ] && replace=1
backup=$dst/backups/constack-$(date +%Y%m%d-%H%M%S)
conflicts=()

link() { # link <file in this repo> <target>
  local from=$src/$1 to=$2
  if [ -L "$to" ] && [ "$(readlink "$to")" = "$from" ]; then echo "ok     $to"; return; fi
  if [ -e "$to" ] || [ -L "$to" ]; then
    if [ $replace = 0 ]; then conflicts+=("$to"); echo "exists $to"; return; fi
    mkdir -p "$backup/$(dirname "${to#"$dst"/}")"; mv "$to" "$backup/${to#"$dst"/}"; echo "moved  $to -> $backup/"
  fi
  mkdir -p "$(dirname "$to")"; ln -s "$from" "$to"; echo "linked $to"
}

for s in "$src"/skills/*/; do link "skills/$(basename "$s")" "$dst/skills/$(basename "$s")"; done
for h in "$src"/hooks/*; do link "hooks/$(basename "$h")" "$dst/hooks/$(basename "$h")"; done
link statusline.js "$dst/statusline.js"
chmod +x "$src"/skills/build/scripts/{wf,afk-loop,check-red-green.sh,require-model.sh,mutate-copy,review-lanes} "$src"/skills/quick/scripts/check-refs "$src"/hooks/* 2>/dev/null

import="@$src/CLAUDE.md"
if [ ! -e "$dst/CLAUDE.md" ]; then printf '%s\n' "$import" > "$dst/CLAUDE.md"; echo "added  $dst/CLAUDE.md (imports $src/CLAUDE.md)"
elif grep -qxF "$import" "$dst/CLAUDE.md"; then echo "ok     $dst/CLAUDE.md imports $src/CLAUDE.md"
else echo "todo   $dst/CLAUDE.md: add this line at the top so it loads constack's rules: $import"; fi

if [ ! -e "$dst/settings.json" ]; then cp "$src/settings.example.json" "$dst/settings.json"; echo "added  $dst/settings.json"
else echo "todo   $dst/settings.json exists: merge the keys from $src/settings.example.json by hand"; fi

if [ ${#conflicts[@]} -gt 0 ]; then
  echo "install.sh: ${#conflicts[@]} path(s) already exist and were left alone: ${conflicts[*]}"
  echo "  Fix: re-run as ./install.sh --replace to move them to ~/.claude/backups/constack-<time>/ and link constack's."
  exit 1
fi
