#!/usr/bin/env python3
"""
sync — idempotent macOS dotfiles sync.

  ./sync.py          create symlinks from $HOME into this repo
  ./sync.py export   collect machine-generated artifacts before committing
  ./sync.py -h       show help
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────

DOTFILES = Path(__file__).resolve().parent
HOME     = Path.home()

# ── Colors (no external deps) ─────────────────────────────────────────────────

RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
RED    = "\033[31m"
BLUE   = "\033[34m"

def c(color: str, text: str) -> str:
    """Wrap text in a color code (stripped if not a tty)."""
    if not sys.stdout.isatty():
        return text
    return f"{color}{text}{RESET}"

def header(text: str) -> None:
    print(f"\n{c(BOLD + CYAN, text)}")

def ok(text: str) -> None:
    print(f"  {c(GREEN, '✓')} {text}")

def skip(text: str) -> None:
    print(f"  {c(DIM, '·')} {c(DIM, text)}")

def warn(text: str) -> None:
    print(f"  {c(YELLOW, '⚑')} {text}")

def info(text: str) -> None:
    print(f"  {c(BLUE, '→')} {text}")

def err(text: str) -> None:
    print(f"  {c(RED, '✗')} {text}", file=sys.stderr)

# ── Help ──────────────────────────────────────────────────────────────────────

HELP = f"""
{c(BOLD, 'sync')} — macOS dotfiles sync

{c(BOLD, 'USAGE')}
  ./sync.py [export | -h]

{c(BOLD, 'COMMANDS')}
  {c(CYAN, '(none)')}   Create symlinks from $HOME into this repo. Safe to run many times:
             · already-correct symlinks are left alone  {c(DIM, '(skipped)')}
             · real files are backed up to <file>.bak   {c(YELLOW, '(backed up)')}
             · wrong symlink targets are corrected       {c(GREEN, '(re-linked)')}

  {c(CYAN, 'export')}   Collect machine-generated artifacts into the repo before committing.
           Updates: Brewfile, asdf/tool-versions, claude/plugins manifests.

  {c(CYAN, '-h')}       Show this message.

{c(BOLD, 'SYNCED FILES')}
  {c(DIM, 'Config           Repo path                                  Home path')}
  {c(DIM, '─' * 79)}
  Helix            helix/config.toml                          ~/.config/helix/config.toml
  Helix theme      helix/themes/gruvbox_transparent.toml      ~/.config/helix/themes/…
  WezTerm          wezterm/wezterm.lua                        ~/.wezterm.lua
  Zsh              zsh/zshrc                                  ~/.zshrc
  Zsh env          zsh/zshenv                                 ~/.zshenv
  Zsh profile      zsh/zprofile                               ~/.zprofile         (if present)
  Git              git/gitconfig                              ~/.gitconfig
  Git (Toptal)     git/toptal.gitconfig                       ~/work/toptal/.gitconfig
  SSH              ssh/config                                 ~/.ssh/config
  asdf versions    asdf/tool-versions                         ~/.tool-versions    (if present)
  Claude           claude/CLAUDE.md                           ~/.claude/CLAUDE.md (if present)
  Claude           claude/settings.json                       ~/.claude/settings.json
  Claude           claude/agents/*                            ~/.claude/agents/*
  Claude           claude/commands/*                          ~/.claude/commands/*
  Claude skills    claude/skills/                             ~/.claude/skills/   (whole dir)
  Claude plugins   claude/plugins/marketplaces.txt            reinstalled via claude CLI
                   claude/plugins/plugins.txt

{c(BOLD, 'SECRETS')}
  ~/.zshrc.secrets is {c(RED, 'NOT')} tracked in git. It is sourced at the end of ~/.zshrc.
  A commented template is created on first run — fill in your tokens there.

{c(BOLD, 'WORKFLOW')}
  {c(CYAN, '── New machine')} ──────────────────────────────────────────────────────────────
    git clone <repo> ~/work/dotfiles
    cd ~/work/dotfiles && ./sync.py
    brew bundle --file=Brewfile

  {c(CYAN, '── After installing packages / plugins on one Mac')} ────────────────────────
    ./sync.py export
    git add . && git commit && git push

  {c(CYAN, '── Pick up on the other Mac')} ──────────────────────────────────────────────
    git pull && ./sync.py
"""

# ── Symlink helper ────────────────────────────────────────────────────────────

linked:    list[str] = []
skipped:   list[str] = []
backed_up: list[str] = []

def link(src: Path, dst: Path) -> None:
    """Create symlink dst → src. Idempotent."""
    if not src.exists():
        return  # not in repo yet; will be linked after export

    dst.parent.mkdir(parents=True, exist_ok=True)

    if dst.is_symlink():
        if dst.resolve() == src.resolve():
            skipped.append(str(dst))
            return
        dst.unlink()  # wrong target — fix it
    elif dst.exists():
        bak = Path(str(dst) + ".bak")
        shutil.move(str(dst), str(bak))
        backed_up.append(str(bak))

    dst.symlink_to(src)
    linked.append(str(dst))

def link_dir_files(src_dir: Path, dst_dir: Path) -> None:
    """Symlink each file in src_dir individually into dst_dir."""
    if not src_dir.is_dir():
        return
    for f in src_dir.iterdir():
        if f.is_file() and not f.name.startswith("."):
            link(f, dst_dir / f.name)

# ── Export ────────────────────────────────────────────────────────────────────

def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)

def export_brewfile() -> None:
    r = run(["brew", "bundle", "dump", "--force",
             f"--file={DOTFILES / 'Brewfile'}", "--quiet"])
    if r.returncode == 0:
        ok("Brewfile")
    else:
        err(f"brew bundle dump failed: {r.stderr.strip()}")

def export_tool_versions() -> None:
    tv = HOME / ".tool-versions"
    if tv.exists() and not tv.is_symlink():
        dst = DOTFILES / "asdf" / "tool-versions"
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(tv, dst)
        ok("asdf/tool-versions")

def export_claude_plugins() -> None:
    plugins_dir = DOTFILES / "claude" / "plugins"
    plugins_dir.mkdir(parents=True, exist_ok=True)

    # marketplaces.txt
    mkt_src = HOME / ".claude" / "plugins" / "known_marketplaces.json"
    if mkt_src.exists():
        data  = json.loads(mkt_src.read_text())
        lines = sorted(
            f"{name}:{info['source']['repo']}"
            for name, info in data.items()
            if info.get("source", {}).get("source") == "github"
        )
        (plugins_dir / "marketplaces.txt").write_text("\n".join(lines) + "\n")
        ok(f"claude/plugins/marketplaces.txt  ({len(lines)} marketplaces)")

    # plugins.txt
    inst_src = HOME / ".claude" / "plugins" / "installed_plugins.json"
    if inst_src.exists():
        data    = json.loads(inst_src.read_text())
        plugins = sorted(data.get("plugins", {}).keys())
        (plugins_dir / "plugins.txt").write_text("\n".join(plugins) + "\n")
        ok(f"claude/plugins/plugins.txt        ({len(plugins)} plugins)")

    # Remove accidentally-staged embedded repos from git index
    for subdir in ("claude/plugins/cache", "claude/plugins/marketplaces"):
        run(["git", "-C", str(DOTFILES), "rm", "-r", "--cached", "--force",
             "--quiet", subdir])

def cmd_export() -> None:
    header("Collecting artifacts into repo…")
    export_brewfile()
    export_tool_versions()
    export_claude_plugins()
    print()
    print(c(DIM, f"  Review:  git diff {DOTFILES}"))
    print(c(DIM,  "  Commit:  git add . && git commit && git push"))
    print(c(DIM,  "  Other:   git pull && ./sync.py"))
    print()

# ── Sync ──────────────────────────────────────────────────────────────────────

def sync_symlinks() -> None:
    d = DOTFILES
    h = HOME

    # Helix
    link(d / "helix/config.toml",                     h / ".config/helix/config.toml")
    link(d / "helix/themes/gruvbox_transparent.toml",  h / ".config/helix/themes/gruvbox_transparent.toml")

    # WezTerm
    link(d / "wezterm/wezterm.lua",  h / ".wezterm.lua")

    # Zsh
    link(d / "zsh/zshrc",    h / ".zshrc")
    link(d / "zsh/zshenv",   h / ".zshenv")
    link(d / "zsh/zprofile", h / ".zprofile")

    # Git
    link(d / "git/gitconfig",        h / ".gitconfig")
    (h / "work/toptal").mkdir(parents=True, exist_ok=True)
    link(d / "git/toptal.gitconfig", h / "work/toptal/.gitconfig")

    # SSH
    ssh_dir = h / ".ssh"
    if not ssh_dir.exists():
        ssh_dir.mkdir(mode=0o700)
    link(d / "ssh/config", ssh_dir / "config")

    # asdf
    link(d / "asdf/tool-versions", h / ".tool-versions")

    # Claude — individual files
    claude_src = d / "claude"
    claude_dst = h / ".claude"
    for fname in ("CLAUDE.md", "settings.json"):
        f = claude_src / fname
        if f.exists():
            link(f, claude_dst / fname)

    # Claude — per-file subdirs
    link_dir_files(claude_src / "agents",   claude_dst / "agents")
    link_dir_files(claude_src / "commands", claude_dst / "commands")

    # Claude skills — whole directory symlink
    link(claude_src / "skills", claude_dst / "skills")

def sync_claude_plugins() -> None:
    """Install any marketplace or plugin listed in the manifests that isn't present."""
    if not shutil.which("claude"):
        return

    plugins_dir = DOTFILES / "claude" / "plugins"

    mkt_file  = plugins_dir / "marketplaces.txt"
    plug_file = plugins_dir / "plugins.txt"

    if mkt_file.exists():
        existing_raw = run(["claude", "plugin", "marketplace", "list"]).stdout
        for line in mkt_file.read_text().splitlines():
            line = line.strip()
            if not line:
                continue
            name, repo = line.split(":", 1)
            if name not in existing_raw:
                info(f"Adding marketplace: {c(CYAN, name)}  ({repo})")
                r = run(["claude", "plugin", "marketplace", "add", f"github:{repo}"])
                if r.returncode != 0:
                    err(f"Failed to add {name}: {r.stderr.strip()}")

    if plug_file.exists():
        installed_raw = run(["claude", "plugin", "list"]).stdout
        for plugin in plug_file.read_text().splitlines():
            plugin = plugin.strip()
            if not plugin:
                continue
            if plugin not in installed_raw:
                info(f"Installing plugin: {c(CYAN, plugin)}")
                r = run(["claude", "plugin", "install", plugin])
                if r.returncode != 0:
                    err(f"Failed to install {plugin}: {r.stderr.strip()}")

def ensure_secrets_template() -> None:
    secrets = HOME / ".zshrc.secrets"
    if not secrets.exists():
        secrets.write_text("""\
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
""")
        ok(f"Created {c(YELLOW, '~/.zshrc.secrets')} — fill in your secrets")

def print_summary() -> None:
    if linked:
        header("Linked")
        for f in linked:
            ok(f.replace(str(HOME), "~"))

    if backed_up:
        header("Backed up  (review and delete when satisfied)")
        for f in backed_up:
            warn(f.replace(str(HOME), "~"))

    if skipped:
        header("Already up to date")
        for f in skipped:
            skip(f.replace(str(HOME), "~"))

    print()
    print(c(DIM, f"  brew bundle --file={DOTFILES}/Brewfile   ← install packages on a new machine"))
    print()

def cmd_sync() -> None:
    sync_symlinks()
    sync_claude_plugins()
    ensure_secrets_template()
    print_summary()

# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd in ("-h", "--help"):
        print(HELP)
    elif cmd == "export":
        cmd_export()
    elif cmd == "":
        cmd_sync()
    else:
        err(f"Unknown command: {cmd}")
        print("Run ./sync.py -h for help.")
        sys.exit(1)

if __name__ == "__main__":
    main()
