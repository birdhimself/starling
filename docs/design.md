# Design

What Starling decided, and why. The [README](../README.md) explains how to
use it. When a decision changes, change it here, in the same change that
implements it, rather than working around it.

## Purpose

Starling holds the agent instructions, skills, scripts and checks shared
across my repositories, so they are written once instead of repeated per
project and do not drift apart. It serves every coding agent, not only
Claude Code: Codex and others read the same files.

## Installation model

- **Per repository, by choice.** Starling is installed into a repository
  deliberately. Nothing is installed per user or per machine: no global git
  hooks path, nothing on `PATH`, nothing in `~/.claude` or `~/.codex`. It is
  only used in my own repositories.
- **A copy, not a submodule.** The installer copies the `.starling/` folder
  into the repository, where it is committed. A submodule would have to be
  initialized in every checkout (clones, CI, every `git worktree add`, dev
  containers, hosted agent sessions), and forgetting fails silently: an
  empty folder means no hooks and no skills. A copy moves that cost to
  updates, which are rarer and run by a script. Update diffs also show
  exactly what changed in the instructions.
- **`.starling/` is managed as a whole.** An update deletes and replaces it,
  and `.starling/VERSION` records the installed version. Never edit files in
  it inside a consuming repository; change them in this repository. Local
  edits are overwritten, visibly, in the update's diff.
- **Why the name.** `.agents/` was the first idea, but Codex already reads
  repository skills from `.agents/skills`. Starling needs a folder no tool
  claims.

## Layout in a consuming repository

```
.starling/                       # managed as a whole, replaced on update
├── VERSION
├── AGENTS.md                    # the shared instructions
├── bin/                         # scripts: check-commit-msg, update, ...
├── hooks/                       # git hooks: commit-msg, ...
├── skills/<name>/               # shared skills
├── claude-settings.json         # merged into .claude/settings.json
└── workflows/                   # copied into .github/workflows/
.claude/skills/<name>  -> ../../.starling/skills/<name>   # for Claude Code
.agents/skills/<name>  -> ../../.starling/skills/<name>   # for Codex
.github/workflows/starling-commits.yml                    # CI commit check
.starling.conf                   # optional, owned by the project
AGENTS.md                        # owned by the project, plus one import line
```

Starling also writes a few files outside `.starling/`: the skill links, the
import line in `AGENTS.md`, its entries in `.claude/settings.json` and the
CI workflow. The installer and the updater own exactly those paths and
rewrite them on every update. Everything else belongs to the project,
including its own skills and `.starling.conf`.

## Install and update

- `install` (repository root) bootstraps: it clones Starling's `main`
  shallowly into the git directory and runs that copy's
  `.starling/bin/update`. It is standalone, so `curl ... | sh` works.
- `.starling/bin/update` finds the newest `vX.Y.Z` tag with `git ls-remote`,
  clones it with `--depth 1 --branch` into the git directory (no temporary
  directory, which sandboxes may refuse), and runs the new version's
  `.starling/bin/integrate`, so an update always uses the new version's
  integration. Only git is needed. `STARLING_REPO` overrides the source; the
  tests use a local repository with tags.
- `integrate` replaces `.starling/` (remove, then copy, so a script still
  running from the old copy keeps its file), writes `.starling/VERSION`, and
  sets up what Starling owns outside it: the import line (once, after the
  first heading; a lone `CLAUDE.md` is renamed to `AGENTS.md`), skill links
  (pruned when a skill is gone; a project's own entry of the same name is
  left alone and reported), `starling-*.yml` workflows (with the default
  branch from `origin/HEAD`; pruned when gone), `.claude/settings.json`
  (created, or merged with `jq`: Starling's attribution keys, and hook
  commands under `.starling/bin/` replaced; without `jq`, a note), and the
  hook activation (its note passed on).
- Formatters and bots: every update replaces `.starling/` and the workflows,
  so a project's tools must leave them alone. In a project that uses
  Prettier (a Prettier config or ignore file, or `prettier` in
  `package.json`), `integrate` appends `.starling/` to `.prettierignore`
  with a comment, once, and notes when `jq` rewrote an existing
  `.claude/settings.json`, whose layout Prettier may change. The payload is
  Prettier-clean with default options anyway; Starling's CI checks it with a
  pinned Prettier. For Renovate it prints a `packageRules` entry
  (`matchFileNames` for `.starling/**` and
  `.github/workflows/starling-*.yml`, `enabled: false`) until the config
  mentions `.github/workflows/starling-`; `sh` and `awk` cannot edit JSON5
  safely, so it does not add the entry itself.
- Nothing is committed: the summary lists the changes and the header to use
  (`build: install Starling vX.Y.Z`, `build: update Starling to vX.Y.Z`).
  Both refuse uncommitted changes to tracked files, so the diff stands
  alone, and refuse Starling's own repository.
- husky is reported, not migrated: removing it touches `package.json` and
  the lockfile, which needs npm.
- Releases are `vX.Y.Z` tags. A change reaches other repositories only once
  it is tagged, and each repository moves when it runs the update.

## Project configuration: `.starling.conf`

What a project decides for itself lives in `.starling.conf` at the
repository root, outside `.starling/` so updates never touch it. The
installer does not create it; a project adds it when it needs a setting.

- Format: git's config format, read with `git config --file`. git is already
  required, so there is no parser to write, and the format has sections,
  comments and multi-valued keys.
- `commit.scopes`: the scopes commit headers may use, separated by spaces;
  several `scopes` lines add up. Without it, headers take no scope.
- `commit.requireScope` (boolean, default false): every header must have a
  listed scope, except the messages git writes itself. Only for projects
  whose scopes cover every file; with package scopes only, docs and CI
  commits would have none to use. Setting it without a list is a
  configuration error (exit 2).
- Starling defines no scopes and suggests none. Scopes describe a project's
  structure, so only the project can name them.
- Agents never add scopes to `.starling.conf` to make a commit pass.

## Shared instructions: one import line

The project's `AGENTS.md` gets one line near the top, written once at
install and never touched by updates:

```md
This repository also follows the shared rules in Starling; read them before starting any task: @.starling/AGENTS.md
```

- Claude Code resolves `@path` imports in `AGENTS.md`. The path must not be
  in backticks: imports inside code spans are not resolved. It must end the
  line or be followed by a space: in `@.starling/AGENTS.md.` the period
  becomes part of the path and nothing is imported, silently. A test checks
  Starling's own line; the installer writes it in this form.
- The installer writes it as one line because projects wrap differently.
  Wrapped, with the path ending the last line, the import works too;
  Starling's own `AGENTS.md` wraps it that way.
- Codex does not resolve imports. The sentence asks it to read the file,
  which it does most of the time but not always (see Verified facts). Rules
  that matter are enforced by checks, so a miss costs a failed check, not a
  bad commit.

## Shared rules: `.starling/AGENTS.md`

Rules that hold in every repository and every task; procedures go into
skills. A project's `AGENTS.md` may refine them. Starling's own does:
`.starling/` is its source, so the rule against editing it does not apply
there.

- Questions are asked in one round, up front, so that long work can then run
  unattended.
- Pull request and issue titles are plain sentences. Conventional Commits
  are for commits only, and rebase merges keep titles out of the history.
- Text an agent posts ends with `🤖 Generated with <agent> using <model>`,
  because Claude Code's own line names no model and covers only pull
  requests.
- Agent instructions go in `AGENTS.md`, never `CLAUDE.md`, since Claude Code
  and Codex both read it. A test checks that every `.starling/` path named
  in `.starling/**/*.md` and in this documentation exists.

Considered and left to projects: reading an issue's whole comment thread,
showing visual options rendered, reporting measured results, and rules for
lean implementations.

## Scripts

Scripts are POSIX `sh`, POSIX `awk` and git only. No Node, Python or
compiled binaries: agents run in dev containers that may have only Go or
only Node, a binary would need one build per platform, and git needs `sh` to
run hooks anyway, so `sh` exists wherever a hook runs.

- Count line lengths in characters, not bytes. Under `LC_ALL=C`, `awk` sees
  UTF-8 bytes, and every byte in 0x80-0xBF continues a character:
  `characters = length(s) - gsub(/[\200-\277]/, "", copy)`.
- Ask git rather than re-implementing it, e.g.
  `git interpret-trailers --parse` for trailers and `git stripspace` for
  comment handling.
- Output is written for the model: silent on success; on failure, the line
  and how to fix it. Exit 0 for success, 1 for a broken rule, 2 for usage
  errors. Never interactive. Destructive actions get a dry run.
- File names: a script that runs as a command (`#!/bin/sh`, executable) has
  no extension, so callers do not depend on its language:
  `check-commit-msg`, `scripts/context`, `tests/run`. Git hooks must have
  git's exact name anyway. A file that is sourced or handed to an
  interpreter has `.sh`, no `#!` line and no executable bit:
  `evals/commit-changes/fixture.sh` and each case's `scaffold.sh`, which the
  eval runner starts as `bash scaffold.sh`. This follows the Google Shell
  Style Guide.
- No temporary files: keep data in variables and pipes. Sandboxes refuse
  writes to the system's temporary directory, and a bare `mktemp` ignores
  `TMPDIR` on macOS. Where a skill needs a file, it uses
  `mktemp "${TMPDIR:-/tmp}/name.XXXXXX"`. A test enforces this for scripts.
- Every script has tests in `tests/`, run with `sh tests/run`.

## Commit conventions

The `commit-changes` skill describes the format, and
`.starling/bin/check-commit-msg` enforces it. The reasons:

- **No `chore`.** It becomes a catch-all for anything without an obvious
  type. Instead: dependencies, lockfiles and tooling `build`, CI `ci`,
  documentation and agent instructions `docs`. If no type fits, the commit
  probably mixes topics and should be split.
- **A body is always required.** It says what changed and why, the cause and
  the mechanism, so that a reader of `git log` understands the change
  without the diff.
- **Trailers are one block, the last paragraph.** git only reads the last
  paragraph as trailers, so a blank line between `Refs:` and
  `Co-authored-by:` silently turns `Refs:` into body text. Allowed keys, in
  exactly this casing: `Refs`, `Co-authored-by`, `Signed-off-by`.
- **`Co-authored-by` means an AI wrote or co-wrote the change.** Writing only
  the message does not count: an agent committing someone else's edits adds
  no trailer. It names the model actually running. This is a rule in the
  instructions, not a check, because humans commit too.
- **Closing keywords** such as `Closes #123` belong in the pull request
  body, not in commits.
- **`fixup!`, `squash!` and `amend!` commits** and git's own `Revert "..."`
  and `Merge ...` messages are exempt from the format, but ready pull
  requests and pushes to the default branch reject fixups and merges.

## Enforcement

Rules that must hold are enforced; instructions explain them.

| Layer                            | What                                                  | Catches                                                       |
| -------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------- |
| `.starling/bin/check-commit-msg` | the single implementation of the commit rules         | used by all layers below                                      |
| commit-msg hook                  | `.starling/hooks/commit-msg` via `core.hooksPath`     | every local commit                                            |
| Claude Code hook                 | `.starling/bin/deny-hook-bypass` blocks hook bypasses | agents getting around the hooks                               |
| CI workflow                      | runs the checker over the pushed range                | everything else: web edits, bots, clones without active hooks |

- `core.hooksPath` is local git config, so each clone must activate the
  hooks once: `.starling/bin/activate-hooks`. Claude Code runs it at the
  start of every session (local, container and web); people run it after
  cloning, or a dev container's `postCreateCommand` or a Node `prepare`
  script does (`test ! -d .starling || sh .starling/bin/activate-hooks || true`:
  npm runs `prepare` on every `npm ci`, also in Docker builds that leave
  `.starling/` out, so the test keeps those quiet). It sets the path only
  when it is unset or already `.starling/hooks`. When another tool set it
  (husky sets `.husky/_` and resets it on every `npm install`), it changes
  nothing and prints a note, which reaches the model at session start; CI is
  the backstop until the project moves its hooks to `.githooks/` and drops
  that tool. Dropping the tool leaves its `core.hooksPath` behind, so the
  note ends with the command that takes over:
  `git config --unset core.hooksPath && .starling/bin/activate-hooks`.
- Project hooks live in `.githooks/<name>`. Each of Starling's hooks runs
  its own check, if it has one, then `.githooks/<name>` if it exists and is
  executable (`.starling/bin/run-project-hook`), with the hook's arguments
  and standard input. Forwarded: pre-commit, pre-merge-commit,
  prepare-commit-msg, commit-msg, post-commit, pre-rebase, post-checkout,
  post-merge, post-rewrite, pre-push. Rarer hooks need a file in
  `.starling/hooks/`. Hooks in `.git/hooks/` stop running, as with any
  `core.hooksPath`, and so do the hooks Git LFS installs there.
- The bypass guard blocks `--no-verify` on any git command, `git commit -n`
  (also inside `-anm`), `-c`/`--config-env` overrides of `core.hooksPath` or
  `hook.*`, `GIT_CONFIG_PARAMETERS`/`GIT_CONFIG_COUNT` in front of git, and
  `git config` changes to `core.hooksPath` (except to `.starling/hooks`) or
  `hook.*`. It splits the command as a shell does, including heredocs and
  `$(...)`, so Claude Code's usual `git commit -m "$(cat <<'EOF' ...)"`
  passes even when the message mentions `-n` or `--no-verify`. Input it
  cannot read is allowed; it is a guard, not the enforcement. Not caught:
  git aliases, `sh -c`, `xargs`. Fixture commands in
  `tests/deny-hook-bypass/` pin the behavior.
- The CI workflow (`.starling/workflows/starling-commits.yml`, installed as
  `.github/workflows/starling-commits.yml`; Starling's own copy is
  identical, which a test checks) runs the checker vendored in the same
  repository, so CI and the local hook always run the same version. No setup
  step: git and `sh` are on the runner.
  - Drafts skip the check under a different name: a skipped check counts as
    passing for branch protection, which goes by the latest check of each
    name, so it must never share the real name. GitHub does not evaluate the
    `name:` expression of a skipped job, so a draft's check shows the raw
    expression rather than `Check commits (draft)`. Ugly, but it differs
    from `Check commits`, which is what matters. Evaluating it would mean
    running the job on drafts with every step skipped, a billed runner
    minute per draft push in a private repository.
  - Actions are pinned to a commit with the version as a comment
    (`actions/checkout@<sha> # v7.0.1`), in the template and in Starling's
    own workflows, since a tag can be moved to other code. Starling bumps
    them in its releases; projects' Renovate leaves the file alone.
  - Drafts get their own concurrency group, so a draft's late run cannot
    cancel the run that checks the pull request once it is ready.
  - Ready pull requests and pushes to the default branch reject merge and
    `fixup!` commits (`--reject-merges --reject-fixups`).
  - A final step fails when no range was read (a push that created the
    branch, any other event): a skipped step reports success, and a merge
    gate must not.
  - The template names `main`; the installer puts in the repository's
    default branch when it differs.
- The checker replaces commitlint. commitlint's parser reads body lines such
  as `Note: ...` as the start of the footer and then reports misleading
  errors; the checker uses git's own trailer parsing instead.

## Claude Code settings

`.starling/claude-settings.json`, merged into the project's
`.claude/settings.json` by the installer (with `jq`; without it, the
installer says what to merge). Starling's own `.claude/settings.json` is the
same file, which a test checks.

- `attribution.commit: ""`: Claude Code's built-in trailer is turned off so
  every agent follows the same `Co-authored-by` rule, with correct casing
  and the actual model name. A fixed attribution text could not name the
  model.
- `attribution.pr: ""`: Claude Code's "Generated with Claude Code" line
  names no model and covers only pull requests. The shared rules ask instead
  for a line under every pull request, issue, comment and review an agent
  posts.
- `attribution.sessionUrl: false`: no `Claude-Session` trailer or pull
  request link.
- `SessionStart` runs `activate-hooks || true`: exit 0 is what lets its
  output into the model's context. `PreToolUse` on Bash runs
  `deny-hook-bypass`; exit 2 blocks the command and shows the reason to the
  model. Both use `"$CLAUDE_PROJECT_DIR"`.

## Skills

The rules for skills are in
`.starling/skills/write-skill/references/rules.md`, with
`.starling/skills/write-skill/references/evals.md` for eval cases, because
projects need them too. The lint in `test-skill` checks the mechanical ones,
and a test keeps its verbs equal to the naming table. The reasons behind
them:

- **Where skills live.** Starling's are in `.starling/skills/`, linked from
  `.claude/skills/` and `.agents/skills/`. A project's own are in
  `.agents/skills/<name>/`, where Codex finds them, linked from
  `.claude/skills/<name>` for Claude Code. Claude Code's validator does not
  read links, so a project's `.agents/skills` (which also holds the links to
  Starling's skills) fails `--strict` on that warning alone, which
  `test-skill` treats as expected.
- **Policy files.** Starling's skills are generic and must not carry one
  repository's details. What a repository adds goes into
  `.agents/policy/<skill>.md`, which the skill reads when it runs, so it is
  not loaded into every session the way `AGENTS.md` is.
- **One purpose per skill.** Meta skills such as `ship-issue` chain focused
  skills by name and hold only the order, the hand-offs and the gates.
  Callers name a skill, never a file path or a step number, because paths
  and steps change.
- **A fixed verb table.** The verb in a name says where a skill ends, such
  as `commit-` at local commits and `ship-` at ready pull requests. It
  stays in Starling so that the words mean the same in every repository.
- **Scripts for facts, prose for judgment.** Scripts gather state, validate
  and perform mechanical actions. Anything that must never happen is a hook
  or a CI check, not a sentence in a skill.
- **Adoption is a skill, not the installer's job.** The installer is `sh`
  and does what needs no judgment. Deciding which of a repository's skills
  one of Starling's replaces, what belongs in a policy file and which lines
  of `AGENTS.md` the shared rules made redundant needs a reader, so the
  `adopt-starling` skill does it, after an install and again after any
  update. It ships in `.starling/`, so it always describes the installed
  version, which a prompt in the README could not, and it has eval cases.
  Its `survey` script gathers the facts, including what each policy file
  may hold, read from the skills themselves. It proposes everything in one
  round, writes only what was confirmed and commits nothing, like the
  installer. It never moves into a policy what the repository did not
  already say. The shared rules name the skill, because a smaller model
  asked what an update replaced otherwise compared the files by hand. `adopt-` is its own verb because none of the others ends at
  uncommitted changes to a repository's setup.
- **Evals are asked about.** `test-skill` lints and validates every time and
  asks before running eval cases, because they take minutes and the runner
  reports a cost. `write-skill` writes cases where an eval setup exists and
  asks whether to set one up otherwise.
- **Evals run on a smaller model.** The eval command passes
  `--model sonnet`, so cases do not run on the session's model. A skill that
  only the strongest model follows fails in the sessions that use a smaller
  one, and the smaller model makes a suite cheaper to run. The judge stays
  on Sonnet as well: Haiku's verdicts were less reliable.
- **Sources.** Anthropic's best practices for skills are the spec, together
  with these rules. Anthropic's `skill-creator` is a source of testing
  ideas, not a style model.

## Testing skills

- `claude plugin eval` runs eval cases headlessly, from
  `evals/<skill>/<case>/case.yaml`. Graders: `regex` (on the trace, the last
  message or a file; `contains`, `not_contains`, `count:N`), `tool_used`
  (tool, `input_match`, `min`, `max`), `tool_order`, `file_exists`, `llm` (a
  judge votes three times; Haiku by default, Sonnet is more reliable),
  `baseline`.
- The runner loads only the plugin under test, never project skills.
  `.claude-plugin/plugin.json` at the repository root points `skills` at
  `.starling/skills`, so the skills load as `starling:<name>`. Cases run
  with `--ablation none`: under `with-without`, `tool_used: Skill` graders
  stop counting, and "must not run" cases would grade nothing.
- A case's `scaffold_script` runs (with `--scaffold`) as
  `bash <absolute path>` in the run's working directory with a fresh `HOME`,
  so `$0` finds Starling and the script builds the fixture repository in
  place.
  `evals/commit-changes/fixture.sh` builds a small project with `.starling/`
  copied in and an origin remote.
- The runner turns off every git hook (`core.hooksPath=/dev/null`,
  `hook.*.enabled=false`), and graders cannot run commands after a run. So
  cases grade what git writes itself: `.git/logs/HEAD` (one line per commit,
  amend and rebase step, e.g. `commit (amend): <subject>`,
  `rebase (fixup): <subject>`) and `.git/COMMIT_EDITMSG` (the last full
  message). The fixture empties both before the agent starts.
- Every item in a description's "Do not use for" becomes a case where the
  skill must not run.
- The verb's contract becomes graders, e.g. `review-` never edits
  (`tool_used: Edit, max: 0`), `commit-` never pushes.
- Mocks only cover MCP servers. Skills that call `gh` or `git` need fixture
  repositories, built by the case's scaffold script.
- When any description changes, re-run every skill's "must not run" cases,
  because descriptions compete. Pilot new cases with `--runs 1`: most first
  failures are grader bugs.

## Verified facts

Checked on 2026-11-07 and 2026-11-08 with Claude Code 2.1.319, Codex
0.166.0, git 2.54 and macOS 27.2.

- Claude Code reads `AGENTS.md` and resolves `@path` imports in it,
  including with file tools disabled.
- An `@path` import followed by a period (`@.starling/AGENTS.md.`) is not
  resolved; at the end of a line or on its own line it is.
- Codex reads `AGENTS.md` and leaves `@path` as text. Told in that line to
  read the file, it did so in 2 of 3 runs of a trivial task.
- Codex looks for repository skills in `.agents/skills`.
- Claude Code loads a skill from a symlinked `.claude/skills/<name>`
  directory, the same as from a copy.
- Claude Code runs project `SessionStart` and `PreToolUse` hooks in headless
  sessions.
- Claude Code settings: `attribution.commit` (the commit trailer text, `""`
  hides it), `attribution.pr`, `attribution.sessionUrl` (`false` drops the
  `Claude-Session` trailer and the pull request link).
- `git interpret-trailers --parse` reads only the last paragraph: a `Note:`
  line in the middle of the body is not a trailer, and a blank line between
  two trailers drops the first from the block.
- The `awk` character count works with the macOS `awk`, mawk, gawk and
  busybox `awk`.
- git hooks run in sandboxed Claude Code sessions; only the eval runner
  turns them off.
- In a sandboxed session, `git commit` fails when commits are signed through
  a 1Password agent: the sandbox cannot reach its socket.
- The eval runner's sandbox on macOS cannot run Apple's `/usr/bin/git`
  without another git on `PATH`, such as Homebrew's.
