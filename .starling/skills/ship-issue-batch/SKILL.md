---
name: ship-issue-batch
description: Ships several GitHub issues at once in Claude Code. It surveys them all, settles every question in one round, implements each in its own worktree agent in parallel, has every pull request reviewed by a fresh agent, applies the findings, and brings each pull request to ready. With --stack it joins every pull request into one GitHub stack, so the batch merges in one step. Ends at ready pull requests, never merged. Use when asked to ship, deliver or implement several issues together, in parallel or as a batch. Do not use for a single issue (use `ship-issue`), for implementing without review (use `implement-issue`), for answering review threads (use `resolve-review-threads`), for refining draft issues (use `refine-draft-issues`), or for merging.
argument-hint: "<issue>... [--stack]"
---

# Ship a batch of issues

Ship several issues at once: one worktree agent per issue, while this
session, the orchestrator, holds every decision for the user. Subagents
cannot ask the user anything, so the user is asked at most twice: once
before any code is written, and once after review if anything needs their
judgment.

This skill needs Claude Code: it relies on worktree-isolated subagents
(`isolation: "worktree"`), on resuming a finished subagent by message, and
on Claude Code's `/code-review`. In another agent, say so, and offer the
issues one at a time with the `implement-issue` skill instead.

`{PRIMARY}` is the primary checkout, and `{SCRATCH}` the session's
scratchpad directory, or a temporary directory outside the repository.

## Contract

- **Input:** two or more issues, and optionally `--stack`.
- **Output:** each issue's pull requests, reviewed, fixed and ready with
  green checks, stacked in the agreed order with `--stack`; and a report.
- **Never:** let a subagent decide something the user has not settled;
  reuse a reviewer; mark a pull request ready while something on it is
  undecided; merge.

## 0. Read the policy and check the preconditions

If `.agents/policy/ship-issue-batch.md` exists, read it, and
`.agents/policy/ship-issue.md` too: the batch ships each issue the way
`ship-issue` would. They hold what this repository adds: the command that
prepares an agent's worktree and whether it takes a slot, services that
must run before agents start, how many agents the machine takes at once,
and what each issue's dossier must settle.

- Two or more issues; for one, use the `ship-issue` skill.
- The services the policy names are running.
- Run at most four implementers at once, or the policy's number, and queue
  the rest. Each pull request gets its own reviewer, so the real fan-out is
  larger.
- When the setup takes a slot, give every running agent a distinct one
  from 1 to 9.
- With `--stack`, `gh stack` is required: if `gh stack --help` fails, stop
  and say so.

## Modes

- **Default:** independent pull requests, each based on the default
  branch, each made ready once its own checks are green. If the base
  requires up-to-date branches, every merge sends the next pull request
  through a rebase and another CI run.
- **`--stack`:** after review, every pull request joins one GitHub stack
  in an agreed order. `gh stack merge <number>` merges every pull request
  up to and including that one in one step, so the user merges the batch,
  or its lower part, at once. The price is coupling: taking a pull request
  out of the middle, or amending a lower one, rebases everything above it
  and runs its checks again. Steps marked _stack_ apply only in this mode.

## 1. Survey, without asking yet

For each issue, do what the `implement-issue` skill asks before it
branches: read the whole thread and the code the change lands in, decide
whether it needs a plan, and draft its open questions, pull request split
and plan.

Drop an issue from the batch, and say why, when `implement-issue` would
stop on it: unready, open questions, closed, or already implemented. An
issue blocked by an open issue goes into the question round instead,
whether its blocker is in the batch or not: every implementer branches
from the default branch, so it cannot build on its blocker until that
merges. Recommend a later batch; if the user keeps it, say in its dossier
that its blocker's change is not there.

Record for each remaining issue:

- the decisions it needs, each with options and your recommendation;
- the pull request split and branch names (`<type>/<number>-<slug>`, or as
  the policy says);
- the files it will touch;
- the validation it needs, from `AGENTS.md` and the policy;
- what else the policy says a dossier must settle;
- work that needs agreement first, such as a long regeneration.

Compare the predicted files. Two issues that touch the same files conflict
on rebase: by default, propose running them one after the other. _Stack:_
they may run in parallel; put them next to each other in the order, and
the conflict is resolved once, when stacking.

_Stack:_ draft the order, bottom first. An issue's own pull requests stay
together in their order; overlapping issues, and an issue kept with its
blocker, sit next to each other, the one the other builds on lower; the
rest goes from the most self-contained and lowest-risk change upward, so
that what the user merges first is the safest part.

## 2. Ask once

Put everything to the user in one round: each issue's questions, split and
plan, overlapping issues, work that needs agreement, and _stack:_ the
order. Leave out what the issue, its thread and the repository already
settle. Wait for the answers. Approving the round approves every split,
plan and the order; an issue with an unanswered question stays out of the
batch.

## 3. Implement in parallel

For each issue, write a dossier: the issue number and title, its scope as
settled, the answers, the branch names, the validation, what the policy
says a dossier settles, the commit type and scope, and the line that ends
every pull request body under the shared rules. _Stack:_ also that the
batch is stacked, which changes how an issue with several pull requests
chains them.

Fill in `references/implementer-briefing.md` with the issue's slot,
branches and paths, append the dossier, and spawn the implementer: the
Agent tool, `subagent_type: "general-purpose"`, `isolation: "worktree"`,
`run_in_background: true`, one call per issue in one message, up to the
cap. Keep each implementer's agent id: later steps resume it by message.
Each stops once its draft pull requests are open, or parks a question.

Do not wait for the whole batch: review an issue as soon as its implementer
reports, and start a queued issue as soon as a slot frees.

## 4. Review each pull request independently

For each pull request, bottom of an issue's chain first, fill in
`references/reviewer-prompt.md` and spawn a fresh reviewer:
`general-purpose`, `isolation: "worktree"`, `run_in_background: true`,
with a free slot and a patch path in `{SCRATCH}`. Never reuse a reviewer,
and pass nothing about how the change was made.

Sort every finding the way the `apply-review-findings` skill does: apply,
drop or hold, with the reason for each drop and hold. Findings outside the
pull request's scope become proposed follow-up issues. Then resume the
implementer with the findings, each marked, and the patch path: it applies
them with that skill and replies with the new head commits. A reviewer can
be wrong: when the implementer shows that a finding does not hold, check
that yourself and drop it.

In a chain, review the next pull request only after the one below is
amended and rebased.

## 5. Ask about held findings

Collect the held findings and parked questions of every issue and put them
to the user in one round, each with the proposed fix and the case for and
against. Skip this step when there are none. Resume each affected
implementer with the decisions. A pull request with an undecided item
stays a draft; _stack:_ an issue left undecided stays out of the stack.

## 6. Stack the batch (_stack_ only)

Start once every pull request in the order is reviewed, its fixes are
pushed, and nothing in it is undecided.

1. Release the branches: `git -C <worktree> switch --detach` in each
   implementer's worktree, since a branch checked out in one worktree
   cannot be rebased in another.
2. Create the stack worktree, which owns the stack from now on:
   `git worktree add --detach {PRIMARY}/.claude/worktrees/ship-stack-<first issue> origin/<default>`,
   and prepare it as the policy says, with a free slot.
3. In it, adopt every branch in the agreed order, bottom first, and
   rebase: `gh stack init <branch>...`, then `gh stack rebase`.
4. Check `git status` after every rebase: `gh stack rebase` exits 0 even
   when it stops on a conflict. Resolve conflicts there, resuming the
   implementer of the branch being rebased, with the worktree's path, for
   anything beyond the obvious. Then `git add` the files and
   `gh stack rebase --continue`.
5. Validate the top of the stack, the whole batch combined, with the
   validation `AGENTS.md` gives for a change that touches everything.
6. `gh stack submit --auto` pushes every branch, sets each pull request's
   base to the one below it, and creates the stack. Check with
   `gh stack view --short` and `gh pr view <number> --json baseRefName`.

From here on, change the batch only in the stack worktree, one agent at a
time: `gh stack checkout <branch>`, amend, then `gh stack rebase --upstack`
and `gh stack push`. Implementer worktrees are detached and stale.

## 7. Bring each pull request to ready

For each pull request with no undecided item, _stack:_ bottom first, use
the `finish-pr` skill from the primary checkout. A failure goes to the
implementer of its branch, _stack:_ fixed in the stack worktree as above;
then `finish-pr` waits again for every pull request whose head moved.

## 8. Report

For each issue, in batch order, _stack:_ in stack order:

- each pull request's URL, its CI state, and which one closes the issue;
- the review outcome: findings applied, dropped and why, held and what the
  user decided;
- the validation run and its results;
- anything left out, and proposed follow-up issues; create them only when
  the user asks, with the `triage-issue` skill.

_Stack:_ also the order, the stack worktree's path, and how to merge:
`gh stack merge <number>` merges every pull request up to and including
that one. After merging a lower part, run `gh stack sync` in the stack
worktree if the rest reports being out of date.

Do not merge: merging is the user's call, after their own test.

## Teardown

Keep implementer worktrees until their pull requests merge: they hold the
branches and, for an issue with its own stack, the local `gh stack` state.
_Stack:_ keep the stack worktree until the whole stack has merged; a stack
whose worktree is gone can be brought back with
`gh stack checkout <number>`. Claude Code locks its agents' worktrees while
the session runs: do not force those locks. After a merge, remove a
worktree with `git worktree remove`.

## Stop conditions

- Everything `implement-issue` and `ship-issue` stop for, per issue.
- Fewer than two issues → use `ship-issue`.
- Overlapping issues the user has not decided on → do not start them.
- A parked question or held finding → that issue waits for the second
  round; the rest of the batch carries on.
- A failure in one issue never stops another; report it with its output.
- _Stack:_ a rebase conflict that changes what an issue does, rather than
  how two changes fit together → ask the user.
- Worktree isolation or resuming an agent is unavailable → report it and
  ship the issues one at a time with `ship-issue`.
