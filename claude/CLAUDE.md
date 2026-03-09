@RTK.md

# Global Claude Code Configuration

## Communication

- Be direct and concise. No preamble, no "Great question!", no filler.
- No emojis unless I ask.
- When presenting options, use a numbered list with a clear recommendation.
- When something is unclear or has multiple valid approaches, ask — don't assume.
- Show understanding through correct action, not acknowledgment phrases.

---

## Code Principles

- **Investigate before writing.** Read existing code, find the pattern already in use, then follow it.
- **Minimum viable change.** Do exactly what was asked — nothing more. No extra refactors, no "while I'm here" improvements.
- **No over-engineering.** Three similar lines beat a premature abstraction. Don't design for hypothetical future requirements.
- **Error handling follows existing patterns.** Don't add error handling beyond what the codebase already does unless asked.

---

## Workflow

- Read project `docs/` and `CLAUDE.md` before making architectural decisions.
- Ask for clarification on vague requests — don't interpret generously and build the wrong thing.

---

## Git

- Use conventional commit messages (e.g., `fix:`, `feat:`, `refactor:`).
- Keep commits atomic — one logical change per commit.

---

## Output

- Don't explain what you just did unless the change is non-obvious.
- Don't summarize files you've read back to me.
- When showing code, show only the changed parts with minimal context.

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
