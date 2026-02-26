#!/usr/bin/env bash
# Idempotent dotfiles sync for macOS.
# Creates symlinks from $HOME into this repo. Safe to run many times.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Help ─────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF

sync.sh — macOS dotfiles sync

USAGE
  ./sync.sh [-h|--help]

DESCRIPTION
  Creates symlinks from your home directory into this repo so that editing
  files here takes effect immediately. Safe to run many times:
    · already-correct symlinks are left alone  (skipped)
    · real files are backed up to <file>.bak   (backed up)
    · wrong symlink targets are corrected       (re-linked)

SYNCED FILES
  Config         Repo path                                 Home path
  ─────────────────────────────────────────────────────────────────────────────
  Helix          helix/config.toml                         ~/.config/helix/config.toml
  Helix theme    helix/themes/gruvbox_transparent.toml     ~/.config/helix/themes/…
  WezTerm        wezterm/wezterm.lua                       ~/.wezterm.lua
  Zsh            zsh/zshrc                                 ~/.zshrc
  Zsh env        zsh/zshenv                                ~/.zshenv
  Git            git/gitconfig                             ~/.gitconfig
  Git (Toptal)   git/toptal.gitconfig                      ~/work/toptal/.gitconfig
  SSH            ssh/config                                ~/.ssh/config
  Claude         claude/CLAUDE.md                          ~/.claude/CLAUDE.md       (if present)
  Claude         claude/settings.json                      ~/.claude/settings.json   (if present)
  Claude         claude/agents/*                           ~/.claude/agents/*        (if any)
  Claude         claude/commands/*                         ~/.claude/commands/*      (if any)

SECRETS
  ~/.zshrc.secrets is NOT tracked in git. It is sourced at the end of ~/.zshrc.
  A commented template is created on first run — fill in your tokens there.

BREW
  Install / reconcile packages on a new machine:
    brew bundle --file="$DOTFILES_DIR/Brewfile"

WORKFLOW
  New machine:
    git clone <repo> ~/work/dotfiles
    cd ~/work/dotfiles && ./sync.sh
    brew bundle --file=Brewfile

  After editing a config on one Mac:
    git add … && git commit && git push

  Pick up changes on the other Mac:
    git pull && ./sync.sh

EOF
  exit 0
}

for arg in "$@"; do
  case "$arg" in -h|--help) usage ;; esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────

BACKED_UP=()
LINKED=()
SKIPPED=()

link() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      SKIPPED+=("$dst")
      return
    fi
    # Symlink exists but points somewhere else — fix it
    rm "$dst"
  elif [ -e "$dst" ]; then
    # Real file/dir — back it up before replacing
    mv "$dst" "${dst}.bak"
    BACKED_UP+=("${dst}.bak")
  fi

  ln -s "$src" "$dst"
  LINKED+=("$dst")
}

# ─── Helix ────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/helix/config.toml"                     "$HOME/.config/helix/config.toml"
link "$DOTFILES_DIR/helix/themes/gruvbox_transparent.toml" "$HOME/.config/helix/themes/gruvbox_transparent.toml"

# ─── WezTerm ──────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/wezterm/wezterm.lua"  "$HOME/.wezterm.lua"

# ─── Zsh ──────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/zsh/zshrc"   "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/zshenv"  "$HOME/.zshenv"

# ─── Git ──────────────────────────────────────────────────────────────────────

link "$DOTFILES_DIR/git/gitconfig"  "$HOME/.gitconfig"

mkdir -p "$HOME/work/toptal"
link "$DOTFILES_DIR/git/toptal.gitconfig"  "$HOME/work/toptal/.gitconfig"

# ─── SSH ──────────────────────────────────────────────────────────────────────

[ -d "$HOME/.ssh" ] || mkdir -m 700 "$HOME/.ssh"
link "$DOTFILES_DIR/ssh/config"  "$HOME/.ssh/config"

# ─── Claude ───────────────────────────────────────────────────────────────────

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
