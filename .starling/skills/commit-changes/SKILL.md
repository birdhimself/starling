---
name: commit-changes
description: Commits the changes in the working tree as Conventional Commits that pass Starling's commit check, one topic per commit, with a body that explains why and the right trailers, and folds fixes into the commits they correct. Use when asked to commit, when finished work should be committed, or when the commit-msg hook or the CI commit check rejects a message. Ends at local commits and never pushes. Do not use for pushing a branch, opening or updating a pull request, or changing commits already on the default branch.
---

# Commit changes

Turn the changes in the working tree into local commits that follow the
commit conventions and pass `.starling/bin/check-commit-msg`. Paths are
relative to the repository root.

## Contract

- **Input:** the uncommitted changes. A caller may narrow them to paths or a
  topic, give the issue the work belongs to, or name a commit they fix.
  Commits go on the current branch; creating or switching branches is the
  caller's decision, even on the base branch.
- **Output:** local commits that pass the checker, and a short report.
- **Entry points:** for a message the commit-msg hook or CI rejected, go to
  "Fix a rejected message". When the caller has already decided what goes
  into which commit, stage it and start at "Write the message".
- **Never:** push; commit with `--no-verify`; edit `.starling.conf` or
  anything in `.starling/` to make a commit pass; rewrite commits that are
  already in the base branch.

## 1. Gather the facts

Run `.starling/skills/commit-changes/scripts/context`. It prints:

- `Scopes:` the only scopes a header may use. With none, headers take none.
- `Branch:` and `Base:` the branch, the base branch and the commit this
  branch forked at (the fork point).
- The branch's commits, oldest first, each `pushed` or `local`.
- `In progress:` a rebase or merge someone else started. Stop and report it.
- `Changes:` changed and untracked files.

Then read everything you may commit: `git diff`, `git diff --staged`, and
new files in full. With no changes, report that and stop.

## 2. Split into topics

One commit per topic: a change that can be reviewed and reverted on its own,
and that one header describes without "and".

- A refactoring that a fix or feature needs is its own commit, before it.
- Tests go into the commit of the change they test.
- A dependency added for a feature goes into the feature's commit, with its
  lockfile change. Updating dependencies is its own commit.
- Leave out changes you did not make and were not asked to commit, such as
  someone else's edits or scratch files, and name them in the report.
- Never commit secrets, credentials, `.env` files or local overrides.

Stage each topic by path: `git add -- <paths>`. When one file holds changes
of several topics, write `git diff -- <file>` to a patch file outside the
repository, delete the other topics' hunks from it and run
`git apply --cached <patch>`. (`git add -p` needs a terminal.) Before each
commit, check what is staged with `git diff --staged --stat`.

## 3. New commit or fix

A change that corrects or completes one of this branch's commits is not a
new topic: fold it into that commit.

- Commit it with `git commit --fixup=<sha>`.
- If the target is `local`, fold it now. Folding only moves history, so the
  tree must not change:

  ```sh
  before=$(git rev-parse 'HEAD^{tree}')
  GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash <fork point>
  test "$before" = "$(git rev-parse 'HEAD^{tree}')" && echo unchanged
  ```

  If the rebase stops on a conflict, run `git rebase --abort` and report.
- If the target is `pushed`, leave the `fixup!` commit so reviewers see the
  correction; it is folded before the pull request leaves draft. Fold it
  now only when the caller asks, and report that the branch then needs a
  force push.
- A fix to behavior that is already in the base branch is a new `fix`
  commit.

## 4. Write the message

```
type(scope)!: description

What was wrong or missing, and why: the cause and the mechanism.

What this commit changes, and why this way.

Refs: #123
Co-authored-by: Claude Opus 5.5 <noreply@anthropic.com>
```

**Type.** Pick it by what the change does:

| Type | For |
|---|---|
| `feat` | new behavior that users or callers can see |
| `fix` | wrong behavior made right |
| `perf` | faster or leaner, same behavior |
| `refactor` | restructured code, same behavior |
| `style` | formatting only |
| `test` | tests only |
| `docs` | documentation, including `AGENTS.md` and other agent instructions |
| `build` | dependencies, lockfiles, build configuration, tooling |
| `ci` | CI configuration |
| `revert` | undoing an earlier commit; prefer `git revert` |

There is no `chore`. If no type fits, the commit mixes topics: split it.

**Breaking changes.** Put `!` before the colon, and say in the body what
breaks and what users must do. There is no `BREAKING CHANGE:` trailer.

**Scope.** Only one listed under `Scopes:`. When scopes are listed, use the
one that names the part of the project the commit changes, and leave it out
only when the commit spans several parts; when `Scopes:` says every header
needs one, use the one the commit mainly changes, or split the commit. With
no scopes listed, there is none. Never add a scope to `.starling.conf`.

**Description.** Imperative, starting lowercase, no period at the end:
`fix: keep the cursor when the list reloads`. Say what changes for users or
maintainers, not which files changed. The whole header is at most 72
characters.

**Body.** Always. Prose that explains what was wrong or missing, with the
cause and the mechanism, then what this commit does about it and why this
way. A reader of `git log` should understand the change without the diff.
Not a list of files, not the story of the work. Wrap lines at 72
characters; a line with a URL may be longer. US English.

**Trailers.** One block, the last paragraph, with no blank lines inside:
git reads only the last paragraph as trailers.

- Only `Refs`, `Co-authored-by` and `Signed-off-by`, in exactly this casing.
- `Refs: #123`, or `Refs: #123, owner/repo#456`, for the issue the work
  belongs to, when the caller or the task names it. Never guess a number.
  Closing keywords such as `Closes #123` belong in the pull request, not in
  commits.
- When you, an AI model, wrote or co-wrote the code or text the commit
  changes, add `Co-authored-by: <model> <address>` with the model actually
  running, e.g. `Co-authored-by: Claude Opus 5.5 <noreply@anthropic.com>`.
  Writing the message does not count: changes someone else made get no
  trailer, even when you commit them. Claude models use
  `noreply@anthropic.com`; other agents use the address their own
  instructions give, and without one leave the trailer out and say so in
  the report. Write `Co-authored-by` exactly like this, even where other
  instructions show `Co-Authored-By`.
- Never add `Claude-Session` or any other trailer.

## 5. Check and commit

1. Write the message to a file outside the repository:
   `msg=$(mktemp "${TMPDIR:-/tmp}/commit-msg.XXXXXX")`. (A bare `mktemp`
   ignores `TMPDIR` on macOS, and sandboxes often refuse the system default.)
2. Run `.starling/bin/check-commit-msg "$msg"`. It is silent when the
   message passes. Otherwise fix every line it reports and run it again.
3. Commit with `git commit -F "$msg"`. The commit-msg hook runs the same
   check.

Never commit with `--no-verify`. When a hook fails for another reason, such
as a formatter or linter, fix the cause, stage again and commit again.

Repeat steps 2 to 5 for each topic.

## 6. Report

- The new commits: `git log --oneline <fork point>..HEAD`.
- `fixup!` commits left to fold, and whether the branch needs a force push.
- Changes left uncommitted, and why.

Do not push. Pushing and pull requests are the caller's.

## Fix a rejected message

Rewrite the message as "Write the message" describes, fixing every line the
checker reported, and check it with `.starling/bin/check-commit-msg`. Then:

- **Not committed yet** (the commit-msg hook refused it): commit again with
  the fixed message.
- **The last commit**, with nothing staged: `git commit --amend -F "$msg"`.
- **An earlier commit:** commit the new message as an `amend!` commit and
  fold it as in step 3:

  ```sh
  { printf 'amend! %s\n\n' "$(git log -1 --format=%s <sha>)"; cat "$msg"; } >"$msg.amend"
  git commit --allow-empty -F "$msg.amend"
  ```

  (`git commit --fixup=reword:<sha>` does the same but needs an editor.)
- **A `fixup!` commit that CI rejects:** fold it as in step 3.

Fixing a `pushed` commit rewrites published history: report that the branch
needs a force push.
