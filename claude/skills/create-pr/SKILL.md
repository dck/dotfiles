---
name: create-pr
description: Draft, update, or open a pull request from the current branch. Use when asked to create a PR, write or revise a PR description, summarize branch changes for review, or open a draft PR on GitHub. Opens with a plain-English why, then headed sections for detail.
---

# Create Pull Request

A PR description has two jobs, in this order:

1. Convince a human, in under thirty seconds and without asking anyone, that this
   change should happen.
2. Give a reviewer the few facts the diff does not show.

Job one is the opening paragraph. Job two is everything under the headings.

## The shape

```md
[PROJ-123](https://<jira-host>/browse/PROJ-123)

<Why. Plain English. No heading above it. 2–5 short sentences.>

## What changed

<Behaviour, not mechanics. A short paragraph or 2–4 bullets.>

## <Optional sections — only the ones that carry content>
```

The opening paragraph is **never** under a heading and **always** the first thing
after the ticket line. A reader who stops there must still understand the point.

## The ticket line

When a Jira key is known — from the branch name, commit subjects, or the user — the
first line of the body is a markdown link to it and nothing else:
`[PROJ-123](https://<jira-host>/browse/PROJ-123)`. Take the Jira host
from the repo's docs or `AGENTS.md`; if none names it, ask. Several keys go on that
same line, space-separated. No key, no ticket line — the body starts with the why.

## The opening paragraph is the whole job

It answers **why are we doing this**, and it is read by people whose first language
is not English.

- Short sentences. One idea each. Under 20 words where you can.
- Say what was wrong, or what someone could not do, in ordinary words.
- Lead with the consequence a person felt, not the mechanism. "Every prompt was
  recorded without the user's id, so we cannot tell who is using Chat" — not
  "the annotation was read from the wrong object".
- **No code identifiers, file paths, function names, or type names.** None.
- No jargon a new joiner would look up. If a domain word is unavoidable, spend three
  words explaining it.
- No history of how it was found, who found it, or which review caught it.

Read it back and ask: would a competent engineer who has never opened this repo know
why we are spending time on this? If not, rewrite it.

## Headings carry the detail

Use `##` headings. Keep each section to what a reviewer actually needs.

**`## What changed`** — always present. Behaviour first; a symbol or file name is
fine here when it genuinely locates the change. Bullets are good when there are
several independent changes; prose is better for one.

Then any of these that carry real content, in this order:

- **`## Why this way`** — only when a reviewer would reasonably propose a different
  approach. State the alternative and the one reason it loses. Two or three sentences.
- **`## Testing`** — what a reviewer must do to see it work, or what pins the
  behaviour. Name the tests that matter and what they hold. Do not paste command
  output or counts of passing tests.
- **`## Scope`** — what this deliberately does not touch, and why that is safe. This
  is the section that stops a reviewer asking "did you check X?". Strong when a
  defect class could plausibly exist elsewhere and you checked.
- **`## Merge notes`** — deploy order, migration compatibility, breaking changes,
  a flag that must be flipped first. Only when merging carries a real constraint.
- **`## Follow-ups`** — the ticket that owns the rest. One line each.

Omit every heading that would hold filler. An empty or padded section costs more
than a missing one.

## Length

- Opening paragraph: 2–5 sentences.
- Whole body: aim for **under 400 words**. Past that, a reviewer skims and the
  opening paragraph stops working.
- If it will not fit, the change is probably too big for one PR. Say so rather than
  compressing the why.

## Never put in the body

- Command transcripts, test counts, timing numbers, or any tool output.
- A restatement of the diff, file by file.
- Rejected alternatives beyond the single one `## Why this way` names.
- Code blocks, unless the change *is* a config value or a contract line a reviewer
  must eyeball.
- A ticked checklist.
- Any claim you have not verified in the code.

## Repo templates

Check `.github/PULL_REQUEST_TEMPLATE.md` and `CONTRIBUTING.md`.

If a template exists, keep the headings that carry content and delete the rest — and
put the plain-English why above the first heading even when the template does not ask
for it. A `## Summary` / `## Changes` / `## Testing` / `## Checklist` template maps to:
the why paragraph above `## Summary`, `## Changes` merged into it, `## Testing` per the
rule above, `## Checklist` dropped.

If the repository's written rules require the template kept whole, keep it, still obey
the length guidance, then tell the user the two rules conflict and which you followed.

## Gather context first

Use `--no-pager` on git commands.

```sh
git branch --show-current
BASE_BRANCH=$(git --no-pager remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
MERGE_BASE=$(git merge-base HEAD "${BASE_BRANCH:-main}")
git --no-pager log "$MERGE_BASE"..HEAD --oneline --no-decorate
git --no-pager diff --stat "$MERGE_BASE"..HEAD
```

Read the diff of the important files. The **why** usually is not in the diff — take it
from the ticket, the commit messages, or the user. If you cannot state the why from
evidence, ask rather than invent one.

## Title

- `type(scope): summary [TICKET]` if the repo uses conventional commits, else a short
  imperative line.
- Match the repo's existing titles.
- The title says what changed; the why lives in the body.

## Open or update

```sh
gh pr view --json number,url 2>/dev/null
gh pr create --base "$BASE_BRANCH" --title "$TITLE" --body-file <path>
gh pr edit <n> --title "$TITLE" --body-file <path>
```

Use `--body-file`, not `--body` — a heredoc through `--body` mangles blank lines.
Add `--draft` only if asked. Return the URL.

## Before you post

Read the body once as if you had no context:

1. Does the opening paragraph say why, in words a non-native speaker reads once?
2. Is every code identifier out of that paragraph?
3. Does every heading carry something the diff does not show?
4. Under 400 words?

Fix, then post.

## Never

- Never mark a PR ready for review unless asked.
- Never open a PR the user has not asked you to open.
- Never fabricate a why.
