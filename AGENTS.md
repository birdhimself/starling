# Starling

Starling holds the agent instructions, skills, scripts and checks shared
across my repositories. It is installed into a repository as a `.starling/`
folder.

This repository also follows the shared rules in Starling; read them
before starting any task: @.starling/AGENTS.md

If a `.notes/` folder exists, read `.notes/design.md` (what was decided and
why) and `.notes/roadmap.md` (the steps, their status and the open questions)
before starting any task. When a step is finished, a decision changes or a
question is answered, update those files in the same change. They are private
and must never be copied into this repository.

- `.starling/` is the payload: exactly what a repository receives on install.
  Here it is the source, so the shared rule against editing it does not
  apply.
- Every skill in `.starling/skills/` is linked from `.claude/skills/<name>`
  and `.agents/skills/<name>`, as the installer links it elsewhere, so this
  repository uses its own skills. A test checks the links.
- Scripts use only POSIX `sh`, POSIX `awk` and git, and no temporary files.
- Run the tests with `sh tests/run`.

## Evals

Each skill has eval cases in `evals/<skill>/`, run by `claude plugin eval`.
`.claude-plugin/plugin.json` exists only so that the eval runner loads
`.starling/skills` as a plugin. Run a skill's evals after changing it, and
every skill's "does-not-use-the-skill" cases after changing any skill's
description, because descriptions compete:

```sh
claude plugin eval . --tag commit-changes -j 3 --scaffold \
  --allow-tools Bash Read Write Edit Glob Grep Skill --ablation none \
  --trust-plugin --no-publish --judge-model sonnet --max-cost-usd 10
```

- Runs cost money: about $5 for the nine `commit-changes` cases at three
  runs each. Pilot a new or changed case with `--case <name> --runs 1`.
- The runner turns off git hooks and graders cannot run commands, so cases
  grade what git writes itself: `.git/logs/HEAD` and `.git/COMMIT_EDITMSG`.
- On macOS, the runner's sandbox cannot use Apple's `/usr/bin/git`, which
  forwards to the Command Line Tools; install another git, e.g. Homebrew's.
