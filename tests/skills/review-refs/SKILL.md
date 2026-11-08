---
name: review-refs
description: Reviews widgets and reports findings without changing them. Use when asked to review a widget. Do not use for changing widgets (use the `commit-changes` skill to commit them).
---

# Review

Run `scripts/missing` and read `references/absent.md`.
Follow `.claude/skills/commit-changes/SKILL.md` for commits.
Then use `no-such-skill`, as in step 2 of `commit-changes`.
List issues with `gh api repos/acme/widgets/issues`.
List pull requests with `gh pr list -R acme/widgets`.
