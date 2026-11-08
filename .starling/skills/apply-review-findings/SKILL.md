---
name: apply-review-findings
description: Applies review findings to a pull request's branch. It checks each finding against the code, sorts it into apply, drop or hold, applies the ones that hold, validates, folds each fix into the commit it corrects and pushes, and hands held findings back undecided. Ends at folded, pushed commits. Use when given review findings or a reviewer's patch to apply, such as the output of a code review, or when another skill hands over findings for a pull request. Do not use for answering review threads on GitHub (use `resolve-review-threads`), for reviewing a pull request yourself, for waiting for CI or marking a pull request ready (use `finish-pr`), or for implementing an issue (use `implement-issue`).
argument-hint: "<pr> [findings]"
---

# Apply review findings

Turn a reviewer's findings into corrections of the pull request's own
commits. A reviewer is a source of suggestions, not a list of orders: check
each finding against the code before touching it. Paths are relative to the
repository root.

## Contract

- **Input:** the pull request, by number or branch, and the findings: for
  each, the file and line, the defect, a failure scenario and a proposed
  fix. A reviewer's patch may come with them. A caller may have sorted the
  findings already; then start at "Apply".
- **Output:** the applied fixes folded into the commits they correct and
  pushed; a report of every finding as applied, dropped with the reason,
  or held with its proposed fix and the case for and against; the new head
  commit and the validation run.
- **Never:** decide a held finding; widen the pull request past its topic;
  push a `fixup!`, `squash!` or `amend!` subject; mark the pull request
  ready; merge.

## 0. Read the policy

If `.agents/policy/apply-review-findings.md` exists, read it first. It holds
what this repository adds, such as the validation for each area and the
conventions reviewers tend to miss.

## 1. Check out the branch

Work on the pull request's head branch in a clean checkout of it
(`gh pr checkout <number>`, or `gh stack checkout <branch>` in a stack).
Read the `AGENTS.md` files of the directories the findings touch.

## 2. Sort every finding

Read the code each finding points at before judging it; a finding that is
wrong about what the code does is common. Then sort it:

- **Apply:** a clear defect, or a clear improvement the repository's
  conventions support.
- **Drop:** wrong, or against a convention in an `AGENTS.md`. Record why.
- **Hold:** uncertain. The current behavior may be intended, the fix trades
  one behavior for another, or it reaches past the pull request's topic.
  Keep its proposed fix as a patch in a file outside the repository, made
  with `mktemp "${TMPDIR:-/tmp}/finding.XXXXXX"`.

Weigh a finding by whether the condition it describes can be reached. A
rare race is worth a fix only if the fix is small; a redesign for it is a
drop or a hold. Work a finding reveals that does not belong to this pull
request becomes a proposed follow-up issue.

## 3. Apply

Apply each finding sorted as apply: from the reviewer's patch when its hunk
still fits the code (`git apply` with the hunks of the applied findings
only), otherwise by hand. Fix the cause, not the place where it surfaced:
when a fix needs several new guards or special cases, stop and say that
the approach needs rethinking instead of landing them.

## 4. Validate

Run the validation `AGENTS.md` and the policy give for what the fixes
touch, and add or update tests for behavior a fix changed.

## 5. Fold and push

Commit with the `commit-changes` skill, naming for each fix the commit it
corrects and telling it to fold them now, since the pull request's
commits are pushed. When a fix changes what a commit does, have it reword
that commit's message too, so that the message still describes the
commit. Then push with `git push --force-with-lease`. In a
`gh stack`, amend the lowest branch first, then `gh stack sync` and
`gh stack submit`, so the branches above follow.

## 6. Report

- The pull request and its new head commit.
- Each finding: applied, with the commit it went into; dropped, with the
  reason; or held, with its patch file and the case for and against.
- The validation run and its results.
- Proposed follow-up issues, if any.

Do not mark the pull request ready: the `finish-pr` skill does that.

## Stop conditions

- A finding needs a product decision or widens the scope → hold it.
- A fix grows guards instead of shrinking the problem → stop and report.
- Validation fails for a reason the findings do not explain → report it
  with its output.
- The branch moved on GitHub since you checked it out → fetch, and check
  the findings against the new head first.
