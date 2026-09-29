@RTK.md

# Global Claude Code Configuration

## Memory — brain-mcp only

Use `mcp__brain-mcp__*` for all persistent memory. Never write `.md` files
under `~/.claude/projects/*/memory/` and never maintain `MEMORY.md`.

- `memory_search` — run at the START of every session/task (search the project name + task keywords) BEFORE acting, not only for explicit recall questions. Standing preferences and prior decisions live here (PR-workflow rules, conventions, past mistakes); acting without searching repeats them.
- `memory_store` — store non-trivial conclusions with the right `category`
  (procedures / decisions / learnings / concepts) and tags. Set `project`
  for project-scoped memories; omit for cross-project.
- `memory_update` — correct existing entries (search first).

Schemas are deferred — load with `ToolSearch query="select:mcp__brain-mcp__memory_search,mcp__brain-mcp__memory_store"` before first use.

---

## Communication

- Be direct and concise. No preamble, no "Great question!", no filler.
- No emojis unless I ask.
- When presenting options, use a numbered list with a clear recommendation.
- When something is unclear or has multiple valid approaches, ask — don't assume.
- Show understanding through correct action, not acknowledgment phrases.
- **Always render GitHub PR/issue references as markdown links** (`https://github.com/<owner>/<repo>/pull/<n>`), never bare `#1234`. Applies to every mention — inline and in tables.

---

## Code Principles

- **Investigate before writing.** Read existing code, find the pattern already in use, then follow it.
- **Minimum viable change.** Do exactly what was asked — nothing more. No extra refactors, no "while I'm here" improvements.
- **No over-engineering.** Three similar lines beat a premature abstraction. Don't design for hypothetical future requirements.
- **Error handling follows existing patterns.** Don't add error handling beyond what the codebase already does unless asked.
- **Prefer existing dependencies.** Do not add a new library if the standard library or an existing project dependency already solves the problem well enough. If a new dependency is necessary, state why.
- **Protect public contracts.** Preserve public APIs, CLI behavior, config formats, and data contracts unless the user explicitly asks for a breaking change. If a breaking change is unavoidable, call it out clearly.
- **No comments.** Code is self documenting. Avoid comments by any means. Even if you feel you need to add a comment, avoid it.

---

## Implementation Standards

- When implementing from a spec, schema, or ticket, read ALL required fields and constraints before writing code. Do not submit a first pass that is missing required keys or fields.
- Do not leave placeholder work behind unless explicitly requested. Avoid TODOs, stubs, temporary flags, and half-implemented branches.

---

## Workflow

- Read project `docs/` and `CLAUDE.md` before making architectural decisions.
- Ask for clarification on vague requests — don't interpret generously and build the wrong thing.
- Test what you change. Run the narrowest relevant checks first, then broader validation if needed. Do not claim success unless you actually ran the relevant checks; if you could not run them, say so explicitly.
- Always run linters and formatters (clippy, cargo fmt, rubocop, etc.) before committing or pushing code. Never skip this step even if you think the code is clean.
- **Plans and working docs go to `.ctx/plans/`, not `docs/plans/`.** The `.ctx/` directory is gitignored and is the home for implementation plans, design docs, and other Claude working artifacts. Override any skill that says `docs/plans/`.

---

## Debugging & Bug Fixes

- When fixing bugs or flaky tests, find and fix the root cause. Never apply defensive hacks or workarounds without explicitly stating the tradeoff and getting user approval.

---

## Git Workflow

- Before starting work, confirm which branch to work on. Ask if unclear. Do not assume based on recent activity.
- Ask before destructive, irreversible, or external-impact actions such as deleting data, rewriting history, changing production config, or running migrations.
- Use conventional commit messages (e.g., `fix:`, `feat:`, `refactor:`).
- Keep commits atomic — one logical change per commit.

---

## Rust

- When working on Rust projects: always run `cargo clippy` and `cargo fmt` after changes. Pay attention to `Path` vs `PathBuf` borrow semantics — needless borrow issues with these types have recurred multiple times.

---

## Output

- Don't explain what you just did unless the change is non-obvious.
- Don't summarize files you've read back to me.
- When showing code, show only the changed parts with minimal context.

---

## Security

- Respect security boundaries. Never print, store, or paste secrets, tokens, private keys, or full credentials into code, logs, examples, or diffs. Redact sensitive values by default.

---

## Installed Tools — How to Use Them

> **Strict rule: never use `grep`, `find`, or `cat` directly. Always use the modern alternatives below.
> If you catch yourself writing `grep` or `find`, stop and rewrite with `rg` or `fd`.**

### rg (ripgrep)
Fast content search. Respects `.gitignore` by default. **Use instead of `grep`.**
```bash
rg "pattern"             # search all files
rg -t ruby "pattern"     # filter by file type
rg -l "pattern"          # filenames only
rg --no-heading -n       # plain output for piping
```

### fd
Fast `find` replacement. **Use instead of `find`.**
```bash
fd pattern               # find files by name
fd -e ts pattern         # filter by extension
fd -t f -H pattern       # files only, include hidden
```

### bat
Drop-in `cat` with syntax highlighting. **Use instead of `cat`.**
```bash
bat file.ts              # with line numbers and highlighting
bat -n file.rb           # line numbers only
bat --style plain file   # no decorations (pipe-safe)
```

### ast-grep (`sg`)
Structural/AST-aware code search and rewrite. **Use instead of `grep` for code patterns.**
```bash
sg -p 'console.log($A)' -l js          # find by AST pattern
sg -p 'fn($A, $B)' -l ts              # match call signatures
sg --rewrite 'newFn($A)' -p 'oldFn($A)' src/  # structural rewrite
```

### difftastic (`difft`)
Structural/AST-aware diff — understands syntax, not just lines.
```bash
difft file1.rb file2.rb
GIT_EXTERNAL_DIFF=difft git diff
GIT_EXTERNAL_DIFF=difft git diff HEAD~1
GIT_EXTERNAL_DIFF=difft git show <sha>
```
`difft` and `delta` coexist: `delta` is the default pager for regular `git diff`; reach for `difft` when you need to understand a structural change (renamed variables, refactored blocks, etc.).

### delta
Syntax-highlighted git diffs. Already configured as the default pager. Works automatically with `git diff`, `git log -p`, `git show`.

### Quick substitution reference
| ❌ Never use | ✅ Always use instead |
|---|---|
| `grep "foo" ...` | `rg "foo" ...` |
| `grep -r "foo" .` | `rg "foo"` |
| `grep -rl "foo" .` | `rg -l "foo"` |
| `find . -name "*.rb"` | `fd -e rb` |
| `find . -type f` | `fd -t f` |
| `cat file` | `bat file` |
| `grep` for code structure | `sg -p '...' -l lang` |
