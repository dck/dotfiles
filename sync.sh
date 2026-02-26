#!/usr/bin/env bash
# Idempotent dotfiles sync for macOS.
# Run with no arguments to create symlinks; run with 'export' to collect
# generated artifacts (Brewfile, tool-versions) before committing.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Help ─────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF

sync.sh — macOS dotfiles sync

USAGE
  ./sync.sh [export | -h]

COMMANDS
  (none)   Create symlinks from \$HOME into this repo. Safe to run many times:
             · already-correct symlinks are left alone  (skipped)
             · real files are backed up to <file>.bak   (backed up)
             · wrong symlink targets are corrected       (re-linked)

  export   Collect machine-generated artifacts into the repo before committing.
           Run this when you've installed new brew packages or changed tool
           versions, then commit and push.

  -h       Show this message.

SYNCED FILES
  Config           Repo path                                  Home path
  ───────────────────────────────────────────────────────────────────────────────
  Helix            helix/config.toml                          ~/.config/helix/config.toml
  Helix theme      helix/themes/gruvbox_transparent.toml      ~/.config/helix/themes/…
  WezTerm          wezterm/wezterm.lua                        ~/.wezterm.lua
  Zsh              zsh/zshrc                                  ~/.zshrc
  Zsh env          zsh/zshenv                                 ~/.zshenv
  Zsh profile      zsh/zprofile                               ~/.zprofile          (if present)
  Git              git/gitconfig                              ~/.gitconfig
  Git (Toptal)     git/toptal.gitconfig                       ~/work/toptal/.gitconfig
  SSH              ssh/config                                 ~/.ssh/config
  asdf versions    asdf/tool-versions                         ~/.tool-versions     (if present)
  Claude           claude/CLAUDE.md                           ~/.claude/CLAUDE.md  (if present)
  Claude           claude/settings.json                       ~/.claude/settings.json (if present)
  Claude           claude/agents/*                            ~/.claude/agents/*   (per file)
  Claude           claude/commands/*                          ~/.claude/commands/* (per file)
  Claude skills    claude/skills/                             ~/.claude/skills/    (whole dir)
  Claude plugins   claude/plugins/marketplaces.txt            reinstalled via claude CLI on sync
                   claude/plugins/plugins.txt

SECRETS
  ~/.zshrc.secrets is NOT tracked in git. It is sourced at the end of ~/.zshrc.
  A commented template is created on first run — fill in your tokens there.

WORKFLOW
  ── New machine ──────────────────────────────────────────────────────────────
    git clone <repo> ~/work/dotfiles
    cd ~/work/dotfiles && ./sync.sh
    brew bundle --file=Brewfile

  ── After a month of work on one Mac ─────────────────────────────────────────
    ./sync.sh export          # update Brewfile + tool-versions in repo
    git add . && git commit && git push

  ── Pick up on the other Mac ─────────────────────────────────────────────────
    git pull && ./sync.sh

EOF
  exit 0
}

# ─── Subcommand dispatch ──────────────────────────────────────────────────────

CMD="${1:-}"
case "$CMD" in
  export)  ;;           # handled below after helpers are defined
  -h|--help) usage ;;
  "")      ;;           # default: sync
  *) echo "Unknown command: $CMD"; echo "Run ./sync.sh -h for help."; exit 1 ;;
esac

# ─── Helpers ──────────────────────────────────────────────────────────────────

BACKED_UP=()
LINKED=()
SKIPPED=()

# Link $1 (repo path) to $2 (home path).
# Skips silently if the repo file/dir does not exist yet.
link() {
  local src="$1"
  local dst="$2"

  # Not in repo yet — skip. Will be linked after 'export' populates it.
  [ -e "$src" ] || return 0

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      SKIPPED+=("$dst")
      return
    fi
    rm "$dst"  # wrong target — fix it
  elif [ -e "$dst" ]; then
    mv "$dst" "${dst}.bak"
    BACKED_UP+=("${dst}.bak")
  fi

  ln -s "$src" "$dst"
  LINKED+=("$dst")
}

# ─── Export ───────────────────────────────────────────────────────────────────

do_export() {
  echo "Collecting artifacts into repo..."
  echo ""

  # Brewfile — always regenerate from current brew state
  brew bundle dump --force --file="$DOTFILES_DIR/Brewfile" --quiet 2>&1 | grep -v "^[⠋⠙⠚⠞⠖⠦⠴⠲⠳⠓✔]" || true
  echo "  ✓ Brewfile"

  # asdf tool-versions — copy only if it's still a real file (not yet symlinked)
  if [ -f "$HOME/.tool-versions" ] && [ ! -L "$HOME/.tool-versions" ]; then
    mkdir -p "$DOTFILES_DIR/asdf"
    cp "$HOME/.tool-versions" "$DOTFILES_DIR/asdf/tool-versions"
    echo "  ✓ asdf/tool-versions"
  fi

  # Claude marketplaces — write name:github-repo per line
  if command -v claude &>/dev/null; then
    python3 - <<'PY' "$DOTFILES_DIR/claude/plugins/marketplaces.txt"
import json, sys
path = "$HOME/.claude/plugins/known_marketplaces.json".replace("$HOME", __import__('os').environ['HOME'])
out  = sys.argv[1]
try:
    data = json.load(open(path))
    lines = []
    for name, info in data.items():
        src = info.get("source", {})
        if src.get("source") == "github":
            lines.append(f"{name}:{src['repo']}")
    open(out, "w").write("\n".join(sorted(lines)) + "\n")
    print(f"  ✓ claude/plugins/marketplaces.txt ({len(lines)} marketplaces)")
except FileNotFoundError:
    pass
PY

    # Claude plugins — write plugin@marketplace per line
    python3 - <<'PY' "$DOTFILES_DIR/claude/plugins/plugins.txt"
import json, sys
path = "$HOME/.claude/plugins/installed_plugins.json".replace("$HOME", __import__('os').environ['HOME'])
out  = sys.argv[1]
try:
    data = json.load(open(path))
    plugins = sorted(data.get("plugins", {}).keys())
    open(out, "w").write("\n".join(plugins) + "\n")
    print(f"  ✓ claude/plugins/plugins.txt ({len(plugins)} plugins)")
except FileNotFoundError:
    pass
PY
  fi

  # Claude plugins — remove any accidentally-staged cache/marketplaces from git
  # index (they are nested git repos and must never be committed).
  git -C "$DOTFILES_DIR" rm -r --cached --force --quiet \
    claude/plugins/cache/ \
    claude/plugins/marketplaces/ \
    2>/dev/null || true

  echo ""
  echo "Review changes:  git diff $DOTFILES_DIR"
  echo "Then commit:     git add . && git commit && git push"
  echo "On other Mac:    git pull && ./sync.sh"
  echo ""
  exit 0
}

[ "$CMD" = "export" ] && do_export

# ─── Helix ────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/helix/config.toml"                     "$HOME/.config/helix/config.toml"
link "$DOTFILES_DIR/helix/themes/gruvbox_transparent.toml" "$HOME/.config/helix/themes/gruvbox_transparent.toml"

# ─── WezTerm ──────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/wezterm/wezterm.lua"  "$HOME/.wezterm.lua"

# ─── Zsh ──────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/zsh/zshrc"     "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/zshenv"    "$HOME/.zshenv"
link "$DOTFILES_DIR/zsh/zprofile"  "$HOME/.zprofile"

# ─── Git ──────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/git/gitconfig"  "$HOME/.gitconfig"

mkdir -p "$HOME/work/toptal"
link "$DOTFILES_DIR/git/toptal.gitconfig"  "$HOME/work/toptal/.gitconfig"

# ─── SSH ──────────────────────────────────────────────────────────────────────

[ -d "$HOME/.ssh" ] || mkdir -m 700 "$HOME/.ssh"
link "$DOTFILES_DIR/ssh/config"  "$HOME/.ssh/config"

# ─── asdf ─────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/asdf/tool-versions"  "$HOME/.tool-versions"

# ─── Claude ───────────────────────────────────────────────────────────────────
# Individual files: CLAUDE.md, settings.json, agents/*, commands/*
# Whole directories: skills/, plugins/ — so that tools installing into them
# write directly into the repo (no manual export needed).

CLAUDE_SRC="$DOTFILES_DIR/claude"
CLAUDE_DST="$HOME/.claude"

for fname in CLAUDE.md settings.json; do
  [ -f "$CLAUDE_SRC/$fname" ] && link "$CLAUDE_SRC/$fname" "$CLAUDE_DST/$fname"
done

for subdir in agents commands; do
  if [ -d "$CLAUDE_SRC/$subdir" ]; then
    for f in "$CLAUDE_SRC/$subdir/"*; do
      [ -f "$f" ] && link "$f" "$CLAUDE_DST/$subdir/$(basename "$f")"
    done
  fi
done

# Directory-level symlink: installs via npx go straight into the repo
link "$CLAUDE_SRC/skills"   "$CLAUDE_DST/skills"

# ─── Claude plugins — reinstall missing via claude CLI ────────────────────────
# export writes marketplaces.txt + plugins.txt; sync reads them and installs
# anything not already present. The runtime cache/marketplaces dirs are never
# committed — they are re-created by the install commands.

if command -v claude &>/dev/null; then
  MARKETPLACES_FILE="$CLAUDE_SRC/plugins/marketplaces.txt"
  PLUGINS_FILE="$CLAUDE_SRC/plugins/plugins.txt"

  if [ -f "$MARKETPLACES_FILE" ]; then
    while IFS=: read -r name repo; do
      [ -z "$name" ] && continue
      if ! claude plugin marketplace list 2>/dev/null | grep -q "^  ❯ $name\$\| $name$\|$name"; then
        echo "  → Adding marketplace: $name ($repo)"
        claude plugin marketplace add "github:$repo" 2>/dev/null || true
      fi
    done < "$MARKETPLACES_FILE"
  fi

  if [ -f "$PLUGINS_FILE" ]; then
    INSTALLED=$(claude plugin list 2>/dev/null || true)
    while read -r plugin; do
      [ -z "$plugin" ] && continue
      if ! echo "$INSTALLED" | grep -q "$plugin"; then
        echo "  → Installing plugin: $plugin"
        claude plugin install "$plugin" 2>/dev/null || true
      fi
    done < "$PLUGINS_FILE"
  fi
fi

# ─── Secrets template (first run only) ────────────────────────────────────────

if [ ! -f "$HOME/.zshrc.secrets" ]; then
  cat > "$HOME/.zshrc.secrets" <<'TEMPLATE'
# Machine-specific secrets — NOT tracked in git.
# This file is sourced at the end of ~/.zshrc. Fill in what you need.

# export NPM_TOKEN=
# export SIDEKIQ_KEY=
# export HOMEBREW_GITHUB_API_TOKEN=
# export JIRA_BASE_URL=
# export JIRA_USERNAME=
# export JIRA_API_TOKEN=
# export YANDEX_GPT_API_KEY=
# export YANDEX_FOLDER_ID=
# export MAESTRO_GITHUB_TOKEN=
TEMPLATE
  echo "→ Created ~/.zshrc.secrets — fill in your secrets"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""

if [ ${#LINKED[@]} -gt 0 ]; then
  echo "Linked:"
  for f in "${LINKED[@]}"; do printf "  ✓ %s\n" "$f"; done
fi

if [ ${#BACKED_UP[@]} -gt 0 ]; then
  echo ""
  echo "Backed up (review and delete when satisfied):"
  for f in "${BACKED_UP[@]}"; do printf "  ⚑ %s\n" "$f"; done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo ""
  echo "Already up to date:"
  for f in "${SKIPPED[@]}"; do printf "  · %s\n" "$f"; done
fi

echo ""
echo "Done. To install brew packages:  brew bundle --file=\"$DOTFILES_DIR/Brewfile\""
echo ""
