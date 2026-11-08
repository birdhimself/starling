# Rules for skills

These rules apply to every skill: Starling's own and a repository's. The
`test-skill` skill checks the mechanical ones; the rest need judgment.
Anthropic's best practices for skills apply too, as far as these rules do
not say otherwise.

Contents:

- Purpose and shape
- Contracts
- Names
- Frontmatter and description
- The body of SKILL.md
- Scripts
- Where skills live
- Project policy

## Purpose and shape

- **One purpose per skill.** A skill does one job that someone would ask
  for on its own. If nobody would invoke it by itself, it is a reference
  file or a script of the skill that needs it, not a skill.
- **Meta skills** chain focused skills by name and hold only the order,
  the hand-offs and the gates. They run each phase in a fresh subagent that
  loads only that phase's skill. Subagents do not inherit loaded skills,
  so the briefing names the skill to invoke. A chain that needs no
  judgment between its steps can become a workflow script instead.
- **Scripts for facts, prose for judgment.** Scripts gather state,
  validate and perform mechanical actions. Prose covers decisions and what
  to do with a script's output.
- **Invariants are not prose.** Anything that must never happen is a hook
  or a CI check, not a sentence in a skill. A skill's limits are defaults
  that a caller may extend, such as "stop once the draft pull request is
  open".

## Contracts

Every skill states its contract near the top, under `## Contract`:

- **Input:** what it works on and what a caller may give it.
- **Output:** what exists when it is done, and what it reports.
- **Entry points:** where a caller who has settled the early steps
  starts, such as "if scope and split are already settled, start at
  Branch".
- **Never:** what it must not do, such as pushing for a skill that ends at
  local commits.

Callers refer to a skill by its name, as in "the `commit-changes` skill",
never by its file path or by the number of one of its steps: paths and
steps change, names do not.

## Names

`<verb>-<object>` in kebab-case, the same as the skill's directory, at most
64 characters. In Claude Code the name is the slash command, so it reads as
a command: `/implement-issue 456`. The verb comes from this table, and says
where the skill ends:

| Verb         | Meaning                                                    | Ends at                           |
| ------------ | ---------------------------------------------------------- | --------------------------------- |
| `implement-` | writes code and commits                                    | draft pull request                |
| `review-`    | produces findings, changes nothing                         | findings                          |
| `apply-`     | acts on given findings                                     | folded commits                    |
| `finish-`    | brings an existing pull request to done                    | CI green, ready                   |
| `ship-`      | meta: the whole pipeline                                   | ready pull requests, never merged |
| `refine-`    | improves an issue's specification                          | updated issue                     |
| `resolve-`   | answers review threads, changing code where a remark holds | threads replied to and resolved   |
| `triage-`    | sets classification and links                              | metadata set                      |
| `clean-`     | deletes things, after confirmation                         | removed items                     |
| `generate-`  | creates assets                                             | files                             |
| `commit-`    | creates commits                                            | local commits, never pushed       |
| `write-`     | creates or updates files of its kind                       | files                             |
| `test-`      | runs a suite, changes nothing                              | report                            |

- A skill whose job fits no verb is a sign that it has two purposes. A new
  verb is added to this table in Starling, with its meaning and end point,
  never in one repository.
- One noun per concept: `pr`, not `pull-request`; `issue`; `findings`.
- Singular when a skill takes one item, plural when it works on a set. No
  two names that differ by one letter.
- A repository's own skill never reuses the name of one of Starling's.
- Names may not contain "anthropic" or "claude".
- Rename a skill only where a rule points at a real problem, and then
  everywhere: its directory, its links, its eval cases and every mention.

## Frontmatter and description

The frontmatter holds `name` and `description`. Add another field only
when the skill needs it, such as `argument-hint` for a skill that takes an
argument as a slash command; `claude plugin validate --strict` rejects
fields it does not know.

The description decides when an agent loads the skill, and every skill's
description competes with every other's. It is at most 1024 characters,
has no XML tags, and is written in the third person. In this order:

1. What the skill does and where it ends, starting with a verb: "Commits
   the changes in the working tree as ..."
2. `Use when` and the requests that should load it, in the words people
   use: "Use when asked to commit, when finished work should be committed,
   ..."
3. `Do not use for` and the nearby requests it must not take, each naming
   the skill to use instead where there is one: "(use `test-skill`)".

Every item after "Do not use for" becomes an eval case in which the skill
must not run.

## The body of SKILL.md

- Under 500 lines. Details go into files in `references/`, each linked
  from SKILL.md itself: references are one level deep, and a reference
  file never sends the reader to another one. A reference file over 100
  lines starts with a list of its sections.
- A title, one paragraph on what the skill does, the contract, numbered
  steps, a report section, and stop conditions where the skill must stop
  and ask. Steps are imperative and give one default, not a menu of
  options.
- Paths are relative to the repository root. A skill names its own
  scripts with their full path from there, such as
  `.agents/skills/<name>/scripts/<script>`, so that any agent can run them
  from the root.
- Never restate `AGENTS.md` or the shared rules; they are loaded anyway.
  Name the skill or the rule instead.
- Never hard-code the repository. `gh` uses the current one; for
  `gh api`, write `repos/{owner}/{repo}/...`, which `gh` fills in.
- Keep the terms consistent: one word for one thing throughout.
- No statements that go stale, such as "the new API" or "as of this
  month"; describe what is true.

## Scripts

- A command has a `#!` line, is executable and has no extension, so
  callers do not depend on its language: `scripts/context`. A file that is
  sourced or handed to an interpreter keeps its extension and has neither
  a `#!` line nor the executable bit: `fixture.sh`.
- Starling's scripts use only POSIX `sh`, POSIX `awk` and git, so they run
  in every container. A repository's own scripts may also use what every
  environment of that repository has.
- No temporary files: keep data in variables and pipes, since sandboxes
  refuse writes to the system's temporary directory. Where a skill's prose
  needs a file, it uses `mktemp "${TMPDIR:-/tmp}/<name>.XXXXXX"`, because
  a bare `mktemp` ignores `TMPDIR` on macOS.
- Output is written for the model: nothing on success; on failure, the
  line and how to fix it. Exit 0 for success, 1 for a broken rule, 2 for a
  usage error. Never interactive. Destructive actions get a dry run.
- Every script has tests: Starling's in `tests/run`, a repository's in its
  own test suite.

## Where skills live

- **Starling's skills** live in `.starling/skills/<name>/` of Starling's
  repository, linked from `.claude/skills/<name>` and
  `.agents/skills/<name>` as `../../.starling/skills/<name>`. The
  installer links them the same way into every repository. In any other
  repository, `.starling/` is managed by Starling: change Starling's
  skills in Starling.
- **A repository's own skills** live in `.agents/skills/<name>/`, where
  Codex finds them, linked from `.claude/skills/<name>` as
  `../../.agents/skills/<name>` for Claude Code. A skill that is still a
  real directory in `.claude/skills/` moves to `.agents/skills/` when it
  is next changed.

## Project policy

Starling's skills are generic: Starling is shared by many repositories and
must not carry one repository's details. What a repository adds to one of
them goes into a policy file, never into the skill.

- A Starling skill that depends on such details reads
  `.agents/policy/<skill>.md` when it exists, before its first step, and
  says what that file may hold, such as "the issue types and labels this
  repository uses". The policy refines the skill's defaults; it cannot
  lift the skill's contract.
- `AGENTS.md` keeps what applies to every task, such as the validation
  commands; a policy file holds what matters only while its skill runs,
  so that it is not loaded into every session.
- A policy file is plain Markdown named after the skill, with no
  frontmatter. It states the repository's rules and the commands they
  need, not the skill's steps.
- A repository's own skill keeps its details in itself; policy files are
  for Starling's skills.
