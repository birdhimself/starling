---
name: open-pr
description: Opens a pull request for finished work on the current branch. It rebases the branch onto its base, has its commit messages checked and fixups folded, runs the repository's checks, fills in the repository's pull request template from the actual diff, pushes, and creates a draft pull request. Ends at an open pull request, never marked ready or merged. Use when asked to open, create, send or prepare a pull request for a branch, or to bring the title or description of an open one up to date. Do not use for implementing an issue (use `implement-issue`), for committing without opening a pull request (use `commit-changes`), for marking a pull request ready or waiting for its CI (use `finish-pr`), for acting on review remarks (use `resolve-review-threads`), or for merging.
argument-hint: "[issue]"
---

# Open a pull request

Turn finished work on a branch into a pull request that follows the
repository's template and says only what the diff and the checks support.
Paths are relative to the repository root.

## Contract

- **Input:** the current branch, with its work done. A caller may give the
  issue it belongs to, the base branch, the checks already run on this
  head commit, or say to open it ready for review instead of as a draft.
- **Output:** an open pull request, a draft by default, and a report.
- **Entry point:** when the branch already has an open pull request whose
  title or description is out of date, gather the facts, then start at
  "Write the title and body".
- **Never:** merge; run `gh pr ready`; open a pull request from the default
  branch; change the work to get a check to pass; claim a check that did
  not run; push a rewritten branch without `--force-with-lease`.

## 0. Read the policy

If `.agents/policy/open-pr.md` exists, read it first. It holds what this
repository adds, such as the checks to run, whether pull requests start as
drafts, and reviewers or labels to request.

## 1. Gather the facts

```sh
git fetch origin
.starling/skills/open-pr/scripts/context
```

Pass the base branch as an argument when the caller or the policy names
one other than the default. The script only reads, and prints:

- `Branch:` the branch, and whether it is pushed.
- `Base:` the base, and how far the branch is ahead of and behind it.
- `In progress:` a rebase or merge someone else started.
- `Commits:` the branch's commits, oldest first.
- `Refs:` the issues those commits name.
- `Changes:` uncommitted files.
- `Template:` the repository's pull request template, if it has one.
- `Pull request:` the open one for this branch, or `unknown` when `gh`
  could not say.

Check the stop conditions below against these facts.

Uncommitted changes that belong to the work go through the
`commit-changes` skill first. Changes that clearly do not belong stay out,
and the report names them. When you cannot tell, ask.

## 2. Rebase onto the base

When the branch is behind its base, run `git rebase origin/<base>`, which
also removes merge commits from the branch. On a conflict, run
`git rebase --abort` and stop: resolving one changes the work.

## 3. Check the commits

```sh
.starling/bin/check-commit-msg --range origin/<base>..HEAD --reject-merges --reject-fixups
```

It prints nothing when every message passes. Have the `commit-changes`
skill fold any `fixup!`, `squash!` or `amend!` commit, telling it to fold
pushed ones now, and fix any other message the check reports. Then run the
check again.

## 4. Run the checks

Run the checks that the policy, `AGENTS.md` or `CONTRIBUTING.md` give for
what this branch changes, in that order of preference, and write down each
command and its result. Skip the ones a caller says already passed on this
head commit. When the repository names no checks, say so in the body
rather than inventing some.

A check that fails means the work is not finished: stop and report it.

## 5. Write the title and body

Read the whole change, not only the last commit:
`git log origin/<base>..HEAD` and `git diff origin/<base>...HEAD`. Read
any issue it belongs to with `gh issue view <number> --comments`.

**Title.** A plain sentence that says what changes for users or
maintainers.

**Body.** With a template, keep its headings and their order, fill every
section from the change, write "None" where a section has nothing to say,
and delete the template's HTML comments. Tick a checkbox only for
something that ran or was verified, and leave the others unticked. When
there are several templates, use the one that fits the change. Without a
template, write what the shared rules ask for in a pull request body.

- **Validation** is only what you ran and what the caller reported. Say
  what was not run.
- **Issues.** Write `Closes #<number>` for an issue this branch finishes,
  and `Refs #<number>` for one it only contributes to. The caller and the
  `Refs:` line name the candidates. Never guess a number.
- End the body with the line the shared rules ask for.

Write the body to a file outside the repository:
`body=$(mktemp "${TMPDIR:-/tmp}/pr-body.XXXXXX")`.

## 6. Push and open

```sh
git push -u origin HEAD
gh pr create --draft --base <base> --title "<title>" --body-file "$body"
```

Use `git push --force-with-lease` instead when you rewrote commits that
were already pushed. Leave out `--draft` only when the caller or the policy
says so.

For a pull request that is already open, do not push. Save the new text
with `gh pr edit <number> --title "<title>" --body-file "$body"`.

When `gh` fails, report its error together with the title and the path of
the body file, so that nothing has to be written again.

## 7. Report

The pull request's URL, whether it is a draft, its title, the checks run
with their results, what you rebased or folded, the issue it closes, and
any changes left out. `finish-pr` is the next step for bringing it to
ready. Do not mark it ready or merge it here.

## Stop conditions

- The branch is the default branch, or HEAD is detached → stop, and offer
  to create a branch for the work.
- A rebase or merge is in progress → report it.
- The branch has no commits beyond its base and nothing to commit → report
  it.
- A rebase conflicts → abort it and report it.
- A check fails → report it with its output, and do not push.
- The branch already has an open pull request and nobody asked to update
  it → report its URL, and do not open another.
