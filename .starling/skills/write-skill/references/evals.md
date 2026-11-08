# Eval cases

`claude plugin eval` runs a skill's eval cases as headless agent sessions
and grades what each did. The `test-skill` skill runs them; this file is
about writing them.

Contents:

- Setup
- Which cases a skill needs
- A case
- Graders
- Fixtures
- After writing

## Setup

The runner loads a plugin. A repository with an eval setup has:

- `.claude-plugin/plugin.json` at its root, whose `skills` points at the
  directory of the skills under test: `./.starling/skills` in Starling,
  `./.agents/skills` in a repository with its own skills. The manifest
  exists only so that the runner loads those skills.
- `evals/<skill>/<case>/case.yaml` for each case, often with a
  `scaffold.sh` next to it.
- `evals/results/` in `.gitignore`: the runner writes its results there.

To set this up in a repository that has none, create the manifest with
`name`, a `description` saying it exists only to run the evals, and
`skills`, and add the ignore line.

## Which cases a skill needs

- At least one case for each main path through the skill, and one for each
  entry point a caller may use.
- One case for each item after "Do not use for" in the description, in
  which the skill must not run. Grade that it did not, and that the agent
  did what the request asked instead.
- The verb's contract as graders in every case: a `review-` or `test-`
  skill never edits, a `commit-` skill never pushes, a `clean-` skill
  deletes nothing before confirmation.
- A case for each rule a model is likely to get wrong, such as asking the
  user before an expensive step.

## A case

```yaml
schema_version: "1.1"
name: <skill>-<case>
description: >-
  One sentence on what the case shows.
tags: [<skill>]
context:
  scaffold_script: scaffold.sh
execution:
  prompt: >-
    The request, in the words a person would use.
  max_turns: 20
  timeout_seconds: 600
  allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
runs: 3
graders:
  - name: uses-the-skill
    type: tool_used
    tool: Skill
    input_match: <skill>
```

- Tag every case with its skill's name: `test-skill` runs a skill's cases
  by that tag.
- Name graders as statements of what passed, such as `never-pushes`.
- The prompt is what a person would type. Do not name the skill unless
  people would.

## Graders

Prefer graders that cost nothing; use a judge only for what no pattern can
check, such as whether a commit body explains the cause.

- `tool_used`: a tool was called, with `input_match` (a regular expression
  on the call's input), `min` and `max`. `min: 0, max: 0` means never.
- `regex`: a `pattern` on the agent's last message, on the whole run with
  `target: trace`, or on a file with
  `target: {source: file, path: <path>}`. `match` is `contains` (the
  default), `not_contains` or `count:<n>`; `flags: m` or `i` as needed.
- `llm`: a judge reads the run, with `focus: trace`, and votes three times
  on `criteria`. Write criteria that say exactly what passes and what
  fails. The `test-skill` skill runs judges on Sonnet.
  A long trace reaches the judge with its middle cut out, so a judge can
  miss what happened halfway through a run: grade that with a `regex` on
  the trace, and keep judges for the start and the end of a run.

The runner turns off every git hook, and graders cannot run commands after
a run. Grade what git and the agent leave behind: `.git/logs/HEAD` has a
line for every commit, amend and rebase step (`commit: <subject>`,
`rebase (fixup): <subject>`), `.git/COMMIT_EDITMSG` the last message.

## Fixtures

- `scaffold.sh` runs as `bash <absolute path>` in the run's working
  directory, with a fresh `HOME`, before the agent starts. It builds the
  fixture repository in place. Cases of one skill share a `fixture.sh` in
  `evals/<skill>/`, sourced by each scaffold, which then sets up its case.
  Both are run by an interpreter: no `#!` line, not executable.
- A fixture copies `.starling/` in, from the repository root found
  through `$0`, and writes `.starling/VERSION` as an installed copy has.
- The runner loads only the plugin under test, never a repository's own
  skills. Do not link the skill under test into the fixture's
  `.claude/skills/`.
- Mocks exist only for MCP servers. A skill that calls `git` or `gh` needs
  a fixture repository; there is no network access to GitHub, so a case
  checks the commands the agent ran, not their effect on GitHub.
- Empty or reset what graders read, such as `.git/logs/HEAD`, at the end
  of the scaffold, so that they see only what the agent did.

## After writing

- Pilot new or changed cases with one run each: most first failures are
  grader bugs. Then run the skill's whole suite.
- When a description changes, run every skill's must-not-run cases again:
  descriptions compete, so a change to one can steal another's requests.
