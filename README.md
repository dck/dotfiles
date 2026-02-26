# dotfiles

macOS dotfiles — helix, WezTerm, zsh, git, SSH, Claude Code.

## Quick start

```sh
git clone git@github.com:usanovd/dotfiles.git ~/work/dotfiles
cd ~/work/dotfiles
./sync.sh
brew bundle --file=Brewfile
```

## Workflow

Files in the repo are the source of truth. `sync.sh` creates symlinks from
`$HOME` into the repo, so changes take effect immediately without re-running
the script.

```sh
# After editing a config on one Mac:
git add . && git commit && git push

# Pick up changes on the other Mac:
git pull && ./sync.sh
```

Run `./sync.sh --help` for full details on what gets linked and where.

## Secrets

`~/.zshrc.secrets` is **not tracked in git**. It is sourced by `.zshrc` and
holds machine-specific tokens and API keys. `sync.sh` creates a commented
template on first run.

## Structure

```
helix/          Helix editor config and themes
wezterm/        WezTerm config
zsh/            .zshrc (no secrets) + .zshenv
git/            gitconfig + toptal override
ssh/            SSH client config (no private keys)
claude/         Claude Code — CLAUDE.md, agents/, commands/
Brewfile        Packages managed by brew bundle
sync.sh         Run this to wire everything up
```

## Per-machine setup after sync

- Fill in `~/.zshrc.secrets` with your tokens
- Set `gpg.ssh.signingkey` in git for commit signing (machine-specific key path)
