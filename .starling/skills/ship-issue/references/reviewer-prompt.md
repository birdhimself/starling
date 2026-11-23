# Reviewer prompt

The orchestrator fills in the `{placeholders}`, keeps the parts for its own
agent where the prompt offers one per agent, drops the others, and passes
the result as a fresh reviewer's whole prompt. Add nothing about how the
change was made. `{SETUP}` is the policy's command that prepares a
worktree, or "nothing to prepare" without one.

---

You are reviewing pull request #{PR} in the repository at `{PRIMARY}`.

- **Claude Code:** You run in your own git worktree, your initial working
  directory: run `pwd` and use it as `<WT>`.
- **Antigravity CLI:** Your git worktree is `{WORKTREE}`: use it as
  `<WT>`, and run every command there (`cd <WT> && ...`).

Never change the primary checkout or any other worktree.

Head commit `{HEAD_SHA}`, base branch `{BASE}`.

1. In `<WT>`, `git fetch origin && git checkout --detach {HEAD_SHA}`, and
   check that `git rev-parse HEAD` matches.
2. Prepare the worktree: {SETUP}.
3. Review the changes, and fix in `<WT>` what you find:
   - **Claude Code:** Invoke the `/code-review` command with the arguments
     `high origin/{BASE}...{HEAD_SHA} --fix`: the pull request's changes
     as a range, which needs no forge, with the effort level before it.
     The other way round it reads the level as the target and silently
     reuses the last level. Let it apply its fixes to `<WT>`, and report
     the level it actually ran at, or that its output shows none.
   - **Antigravity CLI:** Review `git diff origin/{BASE}...{HEAD_SHA}`
     yourself. Read the whole diff, then each changed file in full and the
     code that calls what changed, and the `AGENTS.md` of every directory
     the change touches. Look for wrong logic, unhandled cases and errors,
     broken callers, security problems and lost data; for breaks of the
     rules in `AGENTS.md` and the shared rules; and for changed behavior
     without a test. Then try to disprove each candidate: find the input
     or state that triggers it, and drop it when there is none. Fix each
     finding that survives with the smallest change; where the fix is a
     judgment call, leave the code and describe the options. Report the
     level as "own review".
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
