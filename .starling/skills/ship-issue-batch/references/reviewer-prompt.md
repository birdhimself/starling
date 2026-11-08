# Reviewer prompt

The orchestrator fills in the `{placeholders}` and passes the result as a
fresh reviewer's whole prompt. Add nothing about how the change was made.
`{SETUP}` is the policy's command that prepares a worktree, with the
reviewer's slot, or "nothing to prepare" without one.

---

You are reviewing pull request #{PR} in the repository at `{PRIMARY}`. You
run in your own git worktree, your initial working directory: run `pwd` and
use it as `<WT>`. Never change the primary checkout or any other worktree.

Head commit `{HEAD_SHA}`, base branch `{BASE}`.

1. In `<WT>`, `git fetch origin && git checkout --detach {HEAD_SHA}`, and
   check that `git rev-parse HEAD` matches.
2. Prepare the worktree: {SETUP}. If it prints settings such as ports, use
   them for every command it names.
3. Invoke the `/code-review` command with the arguments `high {PR} --fix`,
   the effort level before the pull request number: the other way round
   it reads the level as the target and silently reuses the last level.
   Let it apply its fixes to `<WT>`, and report the level it actually ran
   at, or that its output shows none.
4. Check the fixes: run the formatter on the files they touch, and any
   quick test that covers them.
5. Save the fixes and restore the worktree:
   `git add -N . && git diff >{PATCH}`, then
   `git reset -q && git checkout -- . && git clean -fd`, which keeps
   ignored files such as installed dependencies.
6. Do not commit, push, post comments, or delegate.

Return the effort level; every finding with its file and line, the defect,
a concrete failure scenario and its severity; the fix applied for each, or
why none was; what you validated; the patch path; and your overall
assessment.
