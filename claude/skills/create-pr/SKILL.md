---
name: create-pr
description: Use when the user asks to "create a PR", "draft a PR description", "write a pull request", "open a PR", or asks for help summarizing their current Git branch for a pull request. Triggers on keywords like "PR", "pull request", "draft PR", "open PR", "create PR", "PR description".
---

# Pull Request Description Generator

## Instructions
You are an expert Staff Engineer writing a Pull Request description. You must operate autonomously using the terminal to gather all necessary context, deeply analyze the code changes, and produce a polished, reviewer-friendly PR description in markdown.

You have access to `gh` (GitHub CLI) for interacting with GitHub — creating PRs, fetching repo metadata, linking issues, checking CI status, and more. Use it when appropriate alongside standard `git` commands.

---

### Step 0: Verify Tooling

```sh
command -v gh >/dev/null 2>&1 && echo "gh: available" || echo "gh: not found"
```
If `gh` is available, you can use it in later steps to create the PR directly, fetch open issues, check CI, etc.

### Step 1: Gather Context

Execute **all** of the following terminal commands. Always use `--no-pager` for any git command to prevent hanging on pager input.

1. **Current branch:**
   ```sh
   git branch --show-current
   ```

2. **Default base branch** (reliably detect `main`, `master`, `develop`, etc.):
   ```sh
   git --no-pager remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p'
   ```
   Fallback: if the remote command fails (e.g., no remote), check which of `main`, `master`, `develop` exists with `git branch --list`.

3. **Merge base:**
   ```sh
   MERGE_BASE=$(git merge-base HEAD <base_branch>)
   ```

4. **Change statistics** (file-level overview of what changed):
   ```sh
   git --no-pager diff --stat "$MERGE_BASE"..HEAD
   ```

5. **Full diff** (with overflow guard to protect context window):
   ```sh
   DIFF_LINES=$(git --no-pager diff "$MERGE_BASE"..HEAD | wc -l)
   ```
   - If ≤ 3000 lines: read the full diff with `git --no-pager diff "$MERGE_BASE"..HEAD`.
   - If > 3000 lines: use `--stat` output to identify the most impactful files, then read individual file diffs selectively with `git --no-pager diff "$MERGE_BASE"..HEAD -- path/to/file`.

6. **Commit log:**
   ```sh
   git --no-pager log "$MERGE_BASE"..HEAD --oneline --no-decorate
   ```

7. **PR size assessment** (total lines added/removed):
   ```sh
   git --no-pager diff --shortstat "$MERGE_BASE"..HEAD
   ```

8. **GitHub context** (if `gh` is available):
   ```sh
   # Check if a PR already exists for this branch
   gh pr view --json number,title,state,url 2>/dev/null || echo "No existing PR"
   # Fetch linked issue details if ticket IDs were found
   gh issue view <ISSUE_NUMBER> --json title,body,labels,state 2>/dev/null
   # Repo info (useful for scope/context)
   gh repo view --json name,description,defaultBranchRef 2>/dev/null
   ```

### Step 2: Deep Analysis

Before writing anything, reason through each of the following:

1. **Change classification:** Parse the branch name and commit messages for conventional commit prefixes (`feat`, `fix`, `refactor`, `chore`, `perf`, `docs`, `test`, `ci`, `build`, `style`). Determine the primary and any secondary change types.

2. **Ticket / Issue extraction:** Inspect the branch name and commit messages for issue references (patterns like `PROJ-123`, `#456`, `GH-789`). Collect all found references for the Linked Issues section.

3. **Blast radius:** Identify which modules, services, or domains are touched. Flag cross-cutting changes (shared utilities, DB schemas, API contracts, authentication, configuration).

4. **Risk assessment:**
   - Are there database migrations or schema changes?
   - Are public API signatures or contracts changed?
   - Are feature flags involved?
   - Are there concurrency, security, or data-integrity implications?
   - Are new dependencies introduced?

5. **Bug fix analysis** (if applicable): Deduce the root cause, reproduction steps, and verification steps from the diff context.

6. **Behavioral delta** (if applicable): Identify the before/after for any user-facing or system-facing behavioral change.

7. **PR size check:** If the diff exceeds **+500 lines** of net additions, note this in the description and suggest splitting if logical boundaries exist.

### Step 3: Generate the PR Description

Produce the PR description using the template below. Apply these rules strictly:

**CRITICAL RULES:**

1. **DYNAMIC SECTIONS:** Only include conditional sections (marked with `<!-- IF ... -->` comments) when their trigger condition is met. Remove sections that do not apply — never leave empty placeholders or skeleton sections.

2. **AUTO-CHECK types:** In the "Type of Change" list, mark (`[x]`) only the types that actually apply. Never leave all boxes unchecked.

3. **BUG FIXES → include `🐞 Bug Fix Details`** with root cause, reproduction steps, and verification steps. Deduce from code context. Use `[Needs manual input]` only as a last resort when the context is truly insufficient.

4. **BEHAVIORAL / UI CHANGES → include `📸 Before & After`** explaining the conceptual or visual delta.

5. **BREAKING CHANGES → include `⚠️ Migration & Rollback`** with concrete migration steps and a rollback plan.

6. **SECURITY-SENSITIVE CHANGES → include `🔒 Security Considerations`** (auth changes, input validation, secrets handling, PII exposure, new endpoints, permission changes).

7. **WRITE FOR REVIEWERS:** Use precise technical language. Front-load the most important information. Prefer bullet points over long paragraphs. Reference specific file paths when helpful.

8. **TITLE FORMAT:** Use conventional-commit style: `type(scope): concise imperative description` — e.g., `feat(auth): add OAuth2 PKCE flow for mobile clients`.

9. **NO FILLER:** Do not include generic boilerplate, motivational language, or vague descriptions. Every sentence must carry information.

---

## PR TEMPLATE — START

<!-- Title line: to be used as the PR title -->
## `type(scope): concise imperative description`

### Summary

> _1–3 sentence executive summary. State **what** changed, **why** it changed, and the **impact** on the system or end users. Be specific._

<!-- IF ticket/issue references found in branch name or commits -->
### Linked Issues

- Closes `TICKET-ID`
- Relates to `TICKET-ID`

### Type of Change

- [ ] 🐛 Bug Fix
- [ ] ✨ New Feature
- [ ] 💥 Breaking Change
- [ ] ♻️ Refactor
- [ ] ⚡ Performance Improvement
- [ ] 📚 Documentation
- [ ] 🧪 Tests
- [ ] 🔧 CI / Build / Tooling

### Changes

_Organize by logical domain or module. For each group, list files and a one-line summary._

**`module-or-domain/`**
| File | Change |
| :--- | :----- |
| `path/to/file.ext` | What changed and why |

### How It Works

_Explain the technical approach and key design decisions. Cover architecture, algorithms, data flow changes, or trade-offs. Write for an experienced engineer who has not seen this code before._

<!-- IF BUG FIX -->
### 🐞 Bug Fix Details

**Root Cause:** _Explain the technical reason the bug occurred._

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Observe the incorrect behavior

**Verification:**
- [ ] Concrete step-by-step instructions a reviewer can follow to confirm the fix works

<!-- IF BEHAVIORAL / UI CHANGE -->
### 📸 Before & After

| Before | After |
| :----- | :---- |
| _Previous behavior, output, or screenshot placeholder_ | _New behavior, output, or screenshot placeholder_ |

<!-- IF BREAKING CHANGE -->
### ⚠️ Migration & Rollback

**Migration Steps:**
1. _What consumers, callers, or downstream services need to change_

**Rollback Plan:**
1. _Concrete steps to safely revert if issues arise post-deploy_

**Deprecation Notes:** _Any deprecated APIs, flags, env vars, or config keys._

<!-- IF SECURITY-SENSITIVE (auth, permissions, input validation, secrets, PII, new endpoints) -->
### 🔒 Security Considerations

- _Threat vectors considered and mitigations applied_
- _Input validation, authorization checks, encryption, rate limiting_
- _PII or secrets exposure: does this change handle sensitive data?_

### 🧪 Testing

_Describe the testing strategy and what coverage looks like._

- **Added:** `path/to/new_test.ext` — covers scenario X
- **Updated:** `path/to/existing_test.ext` — added edge case for Y
- **Manual:** Description of manual testing performed and results

### 📋 Reviewer Guide

> _Help reviewers navigate the PR efficiently. Point them to the most important file first, flag areas of complexity or uncertainty, and clarify what is intentionally out of scope._

1. **Start here:** `path/to/core_file.ext` — the central change
2. **Watch for:** _Specific concern, edge case, or trade-off worth a second opinion_
3. **Out of scope:** _Things intentionally deferred to a follow-up_

### Risk Assessment

| Dimension | Level | Notes |
| :-------- | :---- | :---- |
| Blast Radius | 🟢 Low / 🟡 Medium / 🔴 High | _Which systems or users are affected_ |
| Rollback Safety | 🟢 Safe / 🟡 Requires steps / 🔴 Risky | _Is revert straightforward?_ |
| Data Impact | 🟢 None / 🟡 Migrations / 🔴 Destructive | _Database or persistent data changes_ |
| Dependency Risk | 🟢 None / 🟡 Updated / 🔴 New major dep | _Third-party dependency changes_ |

<!-- IF special deploy requirements exist (feature flags, env vars, ordering, monitoring) -->
### 🚀 Deployment Notes

- _Feature flags to enable/disable_
- _Environment variables or config changes required_
- _Deploy ordering constraints (service A before B)_
- _Dashboards or alerts to monitor post-deploy_

### ✅ Checklist

- [ ] Self-reviewed the diff for correctness, readability, and style
- [ ] Tests added or updated with adequate coverage
- [ ] No new warnings, errors, or linter violations introduced
- [ ] Documentation updated (README, API docs, inline comments) where applicable
- [ ] Backwards-compatible, or migration path documented above
- [ ] No secrets, credentials, or PII exposed in code or logs
- [ ] Accessibility impact considered (if UI change)

## PR TEMPLATE — END

### Step 4: Create or Update the PR (if `gh` is available)

After generating the PR description, if `gh` CLI is available and the user asked to **create** (not just draft) a PR:

1. **Check if PR already exists:**
   ```sh
   gh pr view --json number,url 2>/dev/null
   ```

2. **If no PR exists — create one:**
   ```sh
   gh pr create --base <base_branch> --title "type(scope): description" --body "<generated_markdown>"
   ```
   - Add `--draft` if the user asked for a draft PR.
   - Add `--label`, `--assignee`, `--reviewer`, or `--milestone` flags if the user specified them or if they can be inferred from context.

3. **If PR already exists — update the body:**
   ```sh
   gh pr edit <PR_NUMBER> --body "<generated_markdown>"
   ```

4. **Confirm to the user** with the PR URL returned by `gh`.
