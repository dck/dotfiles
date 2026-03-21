---
name: create-pr
description: Use when the user asks to create a PR, draft a PR description, open a pull request, or summarize the current branch for review. Triggers on phrases like "PR", "pull request", "draft PR", "open PR", and "PR description".
---

# Create Pull Request

Draft or create a pull request that is easy for a human reviewer to scan.

## Goal

Produce a concise PR title and body grounded in the actual diff, commit history, and repo conventions.

If the user wants the PR opened and `gh` is available, create or update it.

## Principles

- Optimize for reviewer comprehension, not process theater.
- Prefer short sections and bullets over long prose.
- Include only sections that apply.
- Do not invent testing, issue links, rollout steps, or follow-up work.
- Match the repository's existing PR title style. If the repo uses conventional commits, follow that pattern.

## Gather Context

Use terminal commands to inspect the branch before writing anything. Use `--no-pager` for git commands.

1. Current branch:
   ```sh
   git branch --show-current
   ```

2. Base branch:
   ```sh
   BASE_BRANCH=$(git --no-pager remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
   ```
   If that fails, set `BASE_BRANCH` to a reasonable local default such as `main`, `master`, or `develop`.

3. Merge base:
   ```sh
   MERGE_BASE=$(git merge-base HEAD "$BASE_BRANCH")
   ```

4. Diff summary:
   ```sh
   git --no-pager diff --stat "$MERGE_BASE"..HEAD
   git --no-pager diff --shortstat "$MERGE_BASE"..HEAD
   ```
   Use `git diff` here, not `gh pr diff`; GitHub CLI does not support `--stat` or `--shortstat` on `gh pr diff`.

5. Commit history:
   ```sh
   git --no-pager log "$MERGE_BASE"..HEAD --oneline --no-decorate
   ```

6. Code changes:
   ```sh
   git --no-pager diff "$MERGE_BASE"..HEAD
   ```
   If the diff is too large to read comfortably, inspect the most important files individually instead of dumping everything.

7. Optional GitHub context when `gh` is available:
   ```sh
   gh pr view --json number,title,state,url 2>/dev/null || true
   gh repo view --json name,description,defaultBranchRef 2>/dev/null || true
   ```

## What to Infer

From the diff and commits, determine only what is useful for the PR:

- The main purpose of the change
- Why the change was made
- The major code paths, modules, or surfaces touched
- Whether tests were added, updated, or only run manually
- Whether there are user-facing changes, operational steps, or follow-ups worth calling out
- Any linked issue IDs mentioned in the branch name, commits, or user request

Do not force a risk matrix, blast-radius section, migration section, or bug root-cause write-up unless the change clearly needs it.

## Output

Write a PR title and body in Markdown.

### Title

- Keep it short and specific.
- Use imperative mood.
- Follow repo style.
- If the repo uses conventional commit titles, use: `type(scope): summary`.

### Body Template

Use this structure and omit sections that do not apply.

```md
## Summary

- What changed
- Why it changed
- Expected impact

## Changes

- Key implementation change
- Key implementation change
- Key implementation change

## Testing

<!-- Only if makes sense to mention testing -->

- Automated: `...`
- Manual: `...`

## Linked Issues

<!-- Only if there are linked issues -->

- Fixes #123
- Relates to PROJ-123

## Screenshots

<!-- Only for UI changes -->

## Deployment Notes

<!-- Only when rollout, config, migrations, or ordering matter -->

## Follow-ups

<!-- Only when intentionally deferred work should be visible to reviewers -->
```

## Writing Rules

- Lead with the most important change.
- Keep each bullet concrete and technical.
- Prefer filenames or subsystems when they help reviewers navigate.
- If testing was not run, say that plainly.
- If there is no linked issue, omit the section.
- If the change is trivial, shorten the body instead of filling space.

## Creating or Updating the PR

If the user asked to open or update the PR and `gh` is available:

1. Check for an existing PR:
   ```sh
   gh pr view --json number,url 2>/dev/null
   ```

2. If none exists, create one:
   ```sh
   gh pr create --base <base_branch> --title "<title>" --body "<body>"
   ```
   Add `--draft` if the user asked for a draft PR.

3. If one exists, update it:
   ```sh
   gh pr edit <pr_number> --title "<title>" --body "<body>"
   ```

4. Return the PR URL if GitHub provides one.

## Never

- Never fabricate context that is not in the diff, commits, or user prompt.
- Never dump the full diff into the PR body.
- Never keep empty template sections.
- Never turn the PR into an architecture review or incident report.
