---
name: ship-issue
description: Takes a GitHub issue through the whole pipeline in Claude Code. It implements the issue with implement-issue, has each resulting pull request reviewed by a fresh agent that never saw the implementation, applies the findings with apply-review-findings, asks the user about held findings in one round, and brings each pull request to ready with finish-pr. Ends at ready pull requests, never merged. Use when asked to ship, fully deliver, or implement and review an issue end to end. Do not use for implementing without a review (use `implement-issue`), for shipping several issues at once (use `ship-issue-batch`), for answering review threads (use `resolve-review-threads`), for reviewing an existing pull request on its own, or for merging.
argument-hint: "<issue>"
---

# Ship an issue

Implement an issue, have every pull request reviewed by an agent that never
saw the implementation happen, fold the fixes in, and end with ready pull
requests. What is left for the user is testing the change and merging it.

This skill needs Claude Code: it spawns reviewer subagents in worktrees and
uses Claude Code's `/code-review`. In another agent, say so, and offer the
`implement-issue` skill followed by the `finish-pr` skill instead.

## Contract

- **Input:** an issue as `#456`, `456` or its URL.
- **Output:** the issue's pull requests, reviewed, with the accepted fixes
  folded in, ready with green checks; and a report.
- **Never:** review the implementation yourself in place of a fresh
  reviewer; decide a held finding for the user; mark a pull request ready
  while a held finding on it is undecided; merge.

## 0. Read the policy

If `.agents/policy/ship-issue.md` exists, read it first. It holds what this
repository adds, such as the command that prepares an agent's worktree
(installing dependencies, picking ports) and services that must run.

## 1. Implement

Use the `implement-issue` skill with the issue and follow it completely:
it reads the thread, asks every question up front, gets the split approved,
implements, validates and opens draft pull requests. All of its stop
conditions apply here. It decides on its own whether the issue needs an
approved plan first; let it.

Do not review your own work beyond its validation: the review belongs to
the next step precisely because you wrote the code.

## 2. Review each pull request independently

For each pull request, bottom of a stack first, spawn a fresh reviewer:
the Agent tool with `subagent_type: "general-purpose"` and
`isolation: "worktree"`. Fill in `references/reviewer-prompt.md` with the
repository's path, the pull request number, its head commit, its actual
base branch (the branch below it in a stack), the policy's worktree setup,
and a patch path outside the repository. Pass nothing else: no notes on
how the change was made, and no assessment of your own. Never reuse a
reviewer for a second pull request.

Then use the `apply-review-findings` skill with the pull request, the
reviewer's findings and its patch. It checks each finding against the
code, sorts it into apply, drop or hold, folds the applied fixes into their
commits and pushes. In a stack, review the next pull request only after the
one below is amended and synced: the amend changes what the next reviewer
must see.

A reviewer that cannot be spawned, or cannot run `/code-review`, is a
missing capability: report it rather than reviewing by hand, and leave
the pull requests as drafts.

## 3. Ask about held findings

Collect the held findings of every review. If there are any, put them to
the user in one round: for each, the finding, the proposed fix, and the
case for and against. Report applied and dropped findings without asking.

Apply the fixes the user accepts with the `apply-review-findings` skill,
handing them over as already sorted to apply.

## 4. Bring each pull request to ready

Bottom of a stack first, use the `finish-pr` skill on each pull request
with no undecided finding. It waits for CI, marks the pull request ready,
and fixes one failure before reporting. A failure in an accepted review fix
is your bug to fix in this run, not a reason for another review round.

## 5. Report

In stack order, bottom first:

- each pull request's URL, its CI state, and which one closes the issue;
- the review outcome: findings applied, dropped and why, held and what the
  user decided, or a clean review;
- the validation run and its results;
- anything left out, with the reason, and proposed follow-up issues;
  create them only when the user asks, with the `triage-issue` skill.

Do not merge: merging is the user's call, after their own test.

## Stop conditions

- Everything `implement-issue` stops for.
- A reviewer cannot be spawned or cannot run `/code-review` → report it;
  the pull requests stay drafts.
- A held finding is undecided → that pull request stays a draft.
- CI stays red after one fix → report it with the output.
