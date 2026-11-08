---
name: finish-pr
description: Brings an existing pull request to ready for review with green checks. It folds leftover fixup commits, rebases a branch that is behind its base, waits for CI on the head commit, marks a draft ready and waits for the checks that starts, and fixes one CI failure before reporting. Ends at a ready pull request, never merged. Use when asked to finish a pull request, get it green, mark it ready once CI passes, or watch its CI. Do not use for implementing an issue (use `implement-issue`), for opening a pull request (use `open-pr`), for acting on review findings (use `apply-review-findings`), for answering review threads (use `resolve-review-threads`), or for merging.
argument-hint: "[pr]"
---

# Finish a pull request

Take an open pull request to ready for review with green checks, so that
what is left is the maintainer's test and merge. Paths are relative to the
repository root.

## Contract

- **Input:** a pull request number, or none: then the current branch's.
  A caller may say whether to mark it ready; by default a draft is marked
  ready once its checks allow.
- **Output:** the pull request ready, with green checks on its current
  head commit, and a report.
- **Never:** merge; mark a pull request ready while its checks fail or a
  `fixup!`, `squash!` or `amend!` subject remains; widen the pull request;
  push a rewritten branch without `--force-with-lease`; re-run a failed
  check to clear it without naming its cause.

## 0. Read the policy

If `.agents/policy/finish-pr.md` exists, read it first. It holds what this
repository adds, such as checks that skip on drafts, labels that start
longer test suites, and how long CI usually takes.

## 1. Read the pull request

```sh
gh pr view <number> --json number,url,isDraft,state,headRefName,baseRefName,mergeStateStatus,commits \
  --jq '{number, url, isDraft, state, headRefName, baseRefName, mergeStateStatus, subjects: [.commits[].messageHeadline]}'
```

Stop if it is closed or merged. To change the branch, work on its head
branch in a clean checkout of it.

## 2. Fold leftovers

When a subject starts with `fixup!`, `squash!` or `amend!`, fold it into
the commit it corrects with the `commit-changes` skill, telling it to fold
the pushed commit now, then push with `git push --force-with-lease`.

When `mergeStateStatus` is `BEHIND` and the base requires up-to-date
branches, rebase onto the base, `git fetch origin && git rebase
origin/<base>`, validate as `AGENTS.md` says, and push with lease. For a
branch in a `gh stack`, run `gh stack sync` instead. On a conflict, stop
and report it: resolving it changes the pull request.

## 3. Wait for CI

Run, in the background where the agent can, since it takes minutes:

```sh
.starling/skills/finish-pr/scripts/wait-ci <number> --mark-ready
```

Leave out `--mark-ready` for a pull request that is already ready, or when
the caller said not to mark it. The script waits for every run on the head
commit, refuses leftover fixup subjects, marks a green draft ready, and
waits for the runs that marking it ready starts. Its exit status:

- `0`: green, and ready if asked.
- `1`: a check failed, or it refused; it prints the checks or the
  subjects.
- `3`: no run appeared on the head commit; the repository may have no CI
  for this branch. Report it rather than marking the pull request ready
  without checks.
- `4`: the head moved while it waited, usually by a push. Run it again.

## 4. Fix one failure

When a check fails, read its log, `gh run view <run-id> --log-failed`, and
name the mechanism. A rerun can confirm a pass but never clears a failure:
blaming flakiness needs evidence for that specific cause.

Fix the cause in the commit it belongs to, with the `commit-changes`
skill, validate, push with lease, and wait again without `--mark-ready`.
If the fix needs a decision the pull request did not settle, or the check
fails again, stop and report the failure with its output.

## 5. Report

The pull request's URL, whether it is ready, its checks and the head
commit they ran on, what you folded or rebased, and any failure you fixed
with its cause. Do not merge: merging is the maintainer's call.

## Stop conditions

- The pull request is closed or merged → report it.
- A rebase conflicts → report it; do not resolve it here.
- A check fails after one fix, or its fix needs a decision → report it
  with the output.
- No CI runs on the head commit → report it; do not mark the pull request
  ready without checks.
