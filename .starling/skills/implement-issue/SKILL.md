---
name: implement-issue
description: Implements a GitHub issue given by number, such as `#456`, end to end. It reads the whole thread, settles open questions with the user before writing code, implements with tests, commits, and opens draft pull requests that close the issue on merge, splitting larger work into a stack of reviewable pull requests. Ends at the draft pull requests. Use when asked to implement, build, fix or work on an issue, or to turn an issue into a pull request. Do not use for refining an issue that is not ready (use `refine-draft-issues`), for classifying or linking issues (use `triage-issue`), for reviewing or merging pull requests, or for a change that has no issue.
argument-hint: "<issue>"
---

# Implement an issue

Take one issue and land it as draft pull requests a reviewer can judge.
Ask every open question before writing code, then implement without
checking in on each step. Paths are relative to the repository root.

## Contract

- **Input:** an issue as `#456`, `456` or its URL. A caller whose scope,
  questions and split are already settled, such as a meta skill with the
  user's answers, starts at "Branch".
- **Output:** branches with commits, draft pull requests whose bodies close
  the issue, and a report.
- **Never:** work on the default branch; guess a product decision; merge;
  mark a pull request ready; widen the change past the issue.

## 0. Read the policy

If `.agents/policy/implement-issue.md` exists, read it first. It holds what
this repository adds: the documents to read for each area of the code, the
constraints that bind most changes, the validation each kind of change
needs, how to name branches, and work that needs the user's agreement
before it starts, such as a long regeneration. It applies wherever it is
more specific than this skill.

## 1. Read the whole thread

```sh
gh issue view <number> --comments
gh api 'repos/{owner}/{repo}/issues/<number>/dependencies/blocked_by?per_page=100' \
  --jq '.[] | "#\(.number) \(.state) \(.title)"'
gh pr list --state open --search '<number> in:body'
```

Read every comment, not only the body. Later comments from the repository
owner supersede the body, and the comment that settles a question is often
not the newest. When the body and a comment disagree, the comment wins.

Stop before implementing, and say why, when:

- the issue carries the label the policy uses for an unready issue
  (`draft` by default), or has an "Open questions" section with
  unanswered entries: offer the `refine-draft-issues` skill instead;
- the issue is closed, or an open pull request already implements it: ask
  what the user wants;
- an open issue blocks it, as a relationship or only in prose: name the
  blocker and ask how to proceed.

## 2. Read the code it touches

Read `AGENTS.md`, the `AGENTS.md` of every directory the change lands in,
the documents the policy names for those areas, and the source files
themselves. A plan that names no files is not a plan yet.

## 3. Decide whether to plan

Decide yourself whether the issue needs a written plan approved before any
code; an explicit "plan this first" or "skip the plan" from the user wins.
Plan first when:

- the change spans several packages or subsystems;
- it needs a stack of pull requests;
- it touches an area `AGENTS.md` or the policy marks as frozen or expensive
  to change;
- the approach is genuinely uncertain, and a reviewer could expect another.

Skip it for a single-topic change with an obvious approach: a bug fix, a
copy change, an addition to code that already has a shape for it. When you
plan, use the agent's plan mode if it has one; otherwise write the plan in
your next message and ask for approval. The questions of the next step come
first and fold into the plan, so the user approves once.

## 4. Ask, then propose the split

Ask the user, in one round, everything the issue, its thread and the code
do not settle: product decisions, which of two behaviors is right, what a
number should be, how far the scope reaches. Guessing a product decision
is worse than asking.

In the same message, propose the pull requests:

- **One** when the change is a single reviewable topic.
- **A stack** when it is not, split along topics a reviewer can judge
  separately, such as shared contracts, then server behavior, then the
  interface. Every pull request in a stack builds, passes its tests and
  leaves the application working on its own; one that breaks the build
  until the next lands belongs merged into its neighbor. Prefer three
  substantial pull requests over eight thin ones.

For each, give its title, what it changes, and how it can be verified on
its own. Wait for the answers.

## 5. Branch

Name branches as the policy says, by default `<type>/<number>-<slug>`,
with the type the commits will have.

- One pull request:
  `git fetch origin && git switch --no-track -c <branch> origin/<default branch>`
- A stack needs `gh stack`; if `gh stack --help` fails, stop and say the
  extension is missing. Create every branch up front, bottom first:
  `gh stack init <branch-1> <branch-2> ...`, then check with
  `gh stack view --short`. `gh stack bottom`, `up`, `down` and
  `checkout <branch>` move between them.

## 6. Implement

Work bottom-up through a stack, finishing and committing each branch before
the next. Add or update tests for the changed behavior in the same pull
request. If something ships without coverage on purpose, say so and name
the risk.

Validate each branch with the commands `AGENTS.md` and the policy give for
what it touches. Do not start servers the user runs themselves.

Commit with the `commit-changes` skill, giving it the issue so that each
commit ends with a `Refs: #<number>` trailer. Fold every `fixup!` commit
before a pull request leaves draft.

## 7. Open the pull requests

The closing keyword belongs in the pull request body, never in a commit.

- **One pull request:** its body says `Closes #<number>`.
- **A stack:** only the top pull request, whose merge completes the issue,
  says `Closes #<number>`. Every lower one says `Refs #<number>` and names
  its place in the stack, so that merging it does not close the issue.

Each body has a summary, the validation actually run, the linked issue,
and screenshots or recordings for interface changes. Name changes to the
environment or services explicitly. Write the body to a file:

```sh
gh pr create --draft --title "<plain sentence>" --body-file <path>
```

For a stack, `gh stack submit --auto` creates draft pull requests with
generated titles; correct each with
`gh pr edit <number> --title "..." --body-file <path>`.

## 8. Keep a stack healthy

`gh stack sync` fetches, fast-forwards the base, rebases each branch onto
its parent and pushes with lease. Run it after the base moves or after you
amend a lower branch, then `gh stack submit` again. On a conflict, sync
restores the branches; resolve it with `gh stack rebase`. Never merge the
base into a branch.

## 9. Report

The pull request URLs in stack order, bottom first, and which one closes
the issue; the validation run and its results; anything left out, with the
reason. Work the issue does not cover becomes a proposed follow-up issue:
create it only when the user asks, with the `triage-issue` skill, blocked
by this issue when it builds on this change.

## Stop conditions

- A product decision is open → ask in "Ask, then propose the split".
- The plan or the split is not approved → do not create branches.
- The issue is unready, closed, already implemented or blocked → stop as
  "Read the whole thread" says.
- The policy marks the work as needing agreement first → get it.
- A stack is needed and `gh stack` is missing → stop and say so.
