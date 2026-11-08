---
name: clean-merged-branches
description: Deletes local git branches whose work is already on the base branch, including branches that were rebase-merged or squash-merged, after showing the evidence and getting explicit confirmation. Use when asked to clean up, prune, tidy or delete merged, stale or leftover branches, or to find which local branches are safe to remove. Do not use for creating or renaming branches, for rebasing or resolving conflicts, for merging or closing pull requests, or for pruning anything other than branches. Deleting remote branches is a separate opt-in that this skill never assumes.
---

# Clean merged branches

Delete local branches only after proving their work is on the base branch,
and only with confirmation. Rebase merges and squash merges leave no merge
commit, so `git branch --merged` misses most merged branches: never use it
as the evidence. Paths are relative to the repository root.

## Contract

- **Input:** a request to clean up branches, optionally naming them.
- **Output:** the confirmed branches deleted, and a report with how to
  restore each.
- **Never:** delete a branch without the user's confirmation of that exact
  list; delete the base branch, the current branch, a branch checked out in
  any worktree, or a branch with commits not represented on the base; run
  a blanket `git branch -D`; delete a remote branch unless the user asked
  for exactly that.

## 0. Read the policy

If `.agents/policy/clean-merged-branches.md` exists, read it first. It holds
what this repository adds, such as branches it always keeps.

## 1. Fetch only if asked

`git fetch --prune` is a separate permission from cleaning branches. Ask
first; if the user does not want it, continue without it and say the
report may be stale.

## 2. Gather the evidence

```sh
.starling/skills/clean-merged-branches/scripts/report
```

The script only reads. It classifies each local branch:

- `PROTECTED`: the base branch, the current branch, or a branch checked
  out in a worktree.
- `CANDIDATE`: every commit is on the base by patch equivalence, which
  finds rebase merges, or the branch's tip is the head of a merged pull
  request, which finds squash merges.
- `KEEP`: anything else, including anything that could not be proven.

`--base <ref>` compares against something other than `origin/HEAD`.
`--no-github` skips the lookup of merged pull requests, so squash-merged
branches fall back to `KEEP`.

Show the user the full table: it is the evidence, not a detail. `KEEP`
means not proven safe, which includes branches the script could not
evaluate. Branches such as `backup/*` often hold the only copy of
history from before a squash: when one is `KEEP`, say so rather than
leaving it out.

## 3. Propose the exact list

List the branches you intend to delete, each with its tip and its one-line
evidence, and wait for explicit confirmation. "Clean up my branches" is a
request for this list, not permission to delete it.

## 4. Delete

Run the report again for just the confirmed branches, right before
deleting, and drop any whose status changed:

```sh
.starling/skills/clean-merged-branches/scripts/report <branch>...
```

Then delete one at a time with `git branch -d <branch>`.

`git branch -d` checks ancestry, so it refuses a rebase-merged branch even
though its patches are on the base. At that refusal, name the branch, show
its evidence again, and ask for approval of `git branch -D <branch>` for
that branch alone. Never pass `-D` up front to avoid the question.

## 5. Remote branches are a separate opt-in

`git push origin --delete <branch>` needs its own explicit request. Do not
infer it from permission to clean local branches, do not bundle it into
the same confirmation, and do not run it because the local branch's
upstream is gone. If the user asks for it, confirm the exact list again.

## 6. Report

For each deleted branch, its name and tip, and how to restore it:

```sh
git branch <branch> <tip>
```

`git reflog` and `git fsck --lost-found` can find a tip that was not
written down. A deleted remote branch comes back by pushing the restored
local branch.

## Stop conditions

- A branch is checked out in a worktree → refuse, and name the worktree.
- A branch has commits not represented on the base → refuse, and show how
  many.
- The user asked to delete remote branches without opting in → stop and
  ask.
- The evidence is missing or ambiguous → keep the branch and say why.
