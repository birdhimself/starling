# Starling

Starling holds the agent instructions, skills, scripts and checks shared
across my repositories. It is installed into a repository as a `.starling/`
folder.

This repository also follows the shared rules in Starling; read them
before starting any task: @.starling/AGENTS.md

`README.md` explains how to use Starling, and `docs/design.md` what was
decided and why. Read `docs/design.md` before changing how Starling works.
When a decision changes, update it in the same change. Planned work and open
questions are GitHub issues.

This repository is public, and most repositories that use it are private.
Never name, quote or describe a private repository here: not in files,
tests, commit messages, pull requests or issues. Use neutral examples.

- `.starling/` is the payload: exactly what a repository receives on install.
  Here it is the source, so the shared rule against editing it does not
  apply.
- Every skill in `.starling/skills/` is linked from `.claude/skills/<name>`
  and `.agents/skills/<name>`, as the installer links it elsewhere, so this
  repository uses its own skills. A test checks the links.
- Write and change skills with the `write-skill` skill: its
  `references/rules.md` holds the rules for skills, and the lint of the
  `test-skill` skill checks the mechanical ones, also in `sh tests/run`.
- Scripts use only POSIX `sh`, POSIX `awk` and git, and no temporary files.
- Run the tests with `sh tests/run`.

## Releases

`install` and `.starling/bin/update` install the newest `vX.Y.Z` tag, so a
change reaches other repositories only once it is tagged. Tag `main` after
merging what a release should contain; tags are the maintainer's call. A
repository moves to it with `.starling/bin/update`, or to a given version
with `.starling/bin/update vX.Y.Z`.

## Evals

Each skill has eval cases in `evals/<skill>/`, run by `claude plugin eval`.
`.claude-plugin/plugin.json` exists only so that the eval runner loads
`.starling/skills` as a plugin. Run a skill's evals after changing it, and
every skill's "does-not-use-the-skill" cases after changing any skill's
description, because descriptions compete. The `test-skill` skill runs
them, after asking; by hand:

```sh
claude plugin eval . --tag commit-changes -j 3 --scaffold \
  --allow-tools Bash Read Write Edit Glob Grep Skill --ablation none \
  --trust-plugin --no-publish --judge-model sonnet --max-cost-usd 10
```

- The runner reports the cost at API prices: about $5 for the nine
  `commit-changes` cases at three runs each. Pilot a new or changed case
  with `--case <name> --runs 1`.
- The runner turns off git hooks and graders cannot run commands, so cases
  grade what git writes itself: `.git/logs/HEAD` and `.git/COMMIT_EDITMSG`.
- On macOS, the runner's sandbox cannot use Apple's `/usr/bin/git`, which
  forwards to the Command Line Tools; install another git, e.g. Homebrew's.
