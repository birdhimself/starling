---
name: test-skill
description: Checks skills against Starling's rules for skills and reports what breaks them, without changing anything. It lints names, descriptions, paths, scripts and reference files, validates the skills with Claude Code, and runs their eval cases when the user agrees. Use when asked to test, lint, check or validate a skill or the repository's skills, or when a skill was just created or changed. Do not use for creating, changing or fixing a skill, for reviewing code that is not a skill, or for testing the application itself.
---

# Test a skill

Check skills against Starling's rules for skills and report what breaks
them. Paths are relative to the repository root.

## Contract

- **Input:** the skills to test, by name or path. Without any, all of the
  repository's own skills. A caller may say whether to run the evals.
- **Output:** a report: for each skill, the lint findings, the validation
  result, and the eval scores or why the evals did not run.
- **Never:** change, create or delete files (the eval runner writes its
  results under `evals/results/`, which git ignores); fix what the report
  finds, which is the caller's; commit.

A repository's own skills are the directories in `.agents/skills/` and
`.claude/skills/`, and in Starling itself `.starling/skills/`. In any other
repository, `.starling/skills/` holds Starling's skills: report problems
there as Starling's, to be fixed in Starling.

## 1. Lint

Run `.starling/skills/test-skill/scripts/lint` with the skill directories,
or without arguments for all of the repository's own skills. It prints
nothing when every skill passes. Otherwise it prints one line per problem,
`path:line: problem; fix`, and exits 1. Exit 2 means it found no skills or
was called wrongly: check the paths.

The lint covers what a script can decide. Then read each skill yourself
for what it cannot: a description that does not say what the skill does
and when, a skill with more than one purpose, steps that restate
`AGENTS.md`. Report those as judgment, apart from the lint's findings.

## 2. Validate

If the `claude` command exists, run Claude Code's validator on each
directory that holds the skills under test:

```sh
claude plugin validate <directory> --strict
```

- In Starling: `.starling/skills`.
- In a project: `.agents/skills`, and `.claude/skills` when it holds real
  skill directories rather than links.

The validator takes a directory of skills, not a single skill. It does not
follow links, so in a project it warns that the links to Starling's skills
were not read, and `--strict` makes that warning fail. That warning alone
is expected; any other warning or error is a finding. Without `claude`,
skip this step and say so in the report.

## 3. Evals

Eval cases live in `evals/<skill>/<case>/case.yaml`, next to the plugin
manifest `.claude-plugin/plugin.json`, and are tagged with their skill's
name. Skip this step for skills without cases, and say so.

Unless the caller already decided, ask the user whether to run the cases:
name the skills and how many cases each has. Each case runs three times as
a full agent session, so a suite takes minutes, and the runner reports the
cost at API prices.

When the user agrees, run each skill's cases from the repository root:

```sh
claude plugin eval . --tag <skill> -j 3 --scaffold --trust-plugin \
  --no-publish --ablation none --judge-model sonnet \
  --allow-tools Bash Read Write Edit Glob Grep Skill
```

- `--scaffold` and `--trust-plugin` run the cases' own scaffold scripts,
  which build each case's fixture repository; pass them only for this
  repository's cases.
- `--ablation none` keeps graders that check the skill was loaded counting.
- A case's score is the share of its graders that passed, averaged over its
  runs. The command exits 1 when a case scores below 1.0.
- On macOS, the runner's sandbox cannot run Apple's `/usr/bin/git`; another
  git, such as Homebrew's, must come first on `PATH`.

## 4. Report

For each skill:

- **Lint:** every finding as the lint printed it, or "clean".
- **Judgment:** what you found reading the skill, or nothing.
- **Validation:** passed, the findings, or skipped and why.
- **Evals:** each case's score and pass rate, with the graders that failed
  in a case below 1.0, or skipped and why.

End with whether every skill passed. Do not fix anything.
