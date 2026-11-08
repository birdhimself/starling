---
name: write-skill
description: Creates, changes, renames or splits a skill by Starling's rules for skills, with one purpose, a contract, a verb-object name and a description that says when to use it and when not. It places and links the skill for Claude Code and Codex, writes its eval cases, and tests it with test-skill until the lint passes. Use when asked to create, write, add, change, rename or split a skill, or to turn a repeated workflow into a skill. Do not use for checking a skill without changing it (use `test-skill`), for changing Starling's own skills from another repository, which happens in Starling, or for editing AGENTS.md or other agent instructions.
argument-hint: "<what the skill should do, or the skill to change>"
---

# Write a skill

Create, change, rename or split a skill so that it follows Starling's rules
for skills, place it where both Claude Code and Codex load it, and test it.
Paths are relative to the repository root.

## Contract

- **Input:** what a new skill should do; or the skill to change and how;
  or the skill to split or rename. A caller may give the name and shape
  already settled: then start at "Write".
- **Output:** the skill's files, placed and linked; eval cases where the
  repository has an eval setup, or with the user's agreement a new one; a
  lint that passes; a report.
- **Never:** change `.starling/` in a repository other than Starling's
  own, since every update replaces it; commit, which is the caller's; run
  eval cases without the user's agreement.

## 1. Gather the facts

Run `.starling/skills/write-skill/scripts/context`. It prints:

- whether this is Starling's own repository or a project, and where new
  skills go;
- `Eval setup:` the plugin manifest and where cases go, or none;
- every skill with where it lives and its description, and notes on
  skills that are not where they belong.

Read `.starling/skills/write-skill/references/rules.md` in full before
writing anything. To change, rename or split a skill, read all of its
files, its eval cases, and every mention of its name in the repository
(`git grep -n <name>`).

## 2. Settle the shape

Decide, from the request and the rules:

- **Purpose:** the one job the skill does, and the request that would
  load it on its own. Without such a request it is a reference file or a
  script of the skill that needs it, not a skill.
- **Overlap:** compare the job and its triggers with every description
  the context listed. When another skill already covers part of it,
  change that skill or narrow both descriptions; never leave two skills
  that answer the same request.
- **Name:** a verb from the naming table and the object, and whether the
  skill is a meta skill that chains others.
- **Contract:** input, output, entry points and what it must never do.
- **Facts and judgment:** what a script gathers or checks, and what the
  prose decides. Something that must never happen needs a hook or a CI
  check: say so to the user rather than writing it as a rule in prose.

Ask the user, in one round, whatever the request and the repository leave
open, such as the end point or a name between two fitting verbs. With no
eval setup, ask in the same round whether to set one up.

## 3. Write

- `SKILL.md`: the frontmatter, a title, one paragraph on what the skill
  does, `## Contract`, numbered steps, a report section, and stop
  conditions where it must stop and ask. Under 500 lines.
- `references/<topic>.md` for details that only some runs need, each
  linked from `SKILL.md`.
- `scripts/<command>` for facts, checks and mechanical actions, with
  tests: in Starling in `tests/run`, in a project in its test suite.

When changing a skill, keep what still holds, and update every caller
that names it. When splitting one, give each part one purpose and its own
trigger; what remains of the old skill becomes a meta skill that holds the
order and the hand-offs, or goes. When renaming, move the directory, its
links and its eval cases, change the cases' tags, and update every
mention.

## 4. Place and link

Where the context says new skills go:

- **Starling:** `.starling/skills/<name>/`, then
  `ln -s ../../.starling/skills/<name> .claude/skills/<name>` and the
  same for `.agents/skills/<name>`.
- **A project:** `.agents/skills/<name>/`, then
  `mkdir -p .claude/skills && ln -s ../../.agents/skills/<name> .claude/skills/<name>`.
  A skill you change that is still a real directory in `.claude/skills/`
  moves first, with
  `mkdir -p .agents/skills && git mv .claude/skills/<name> .agents/skills/<name>`,
  then gets the link.

Sandboxes often refuse writes in `.claude/`. Then give the user the
`ln -s` command to run, and say in the report that Claude Code does not
load the skill until the link exists.

## 5. Eval cases

Follow `.starling/skills/write-skill/references/evals.md`.

- With an eval setup, write or update the cases in `evals/<name>/`: one
  for each main path and entry point, one for each "Do not use for" item,
  and the verb's contract as graders.
- Without one, set it up as that file describes if the user agreed, then
  write the cases. Otherwise write nothing for the evals, and list in the
  report each case you would write: its prompt and what it grades.

## 6. Test

Use the `test-skill` skill on the skill, telling it not to run the evals.
Fix every finding it reports and use it again, at most three rounds.
Report what is left after the third.

Once it passes, use it once more on the skills whose descriptions you
changed, and let it ask the user whether to run their eval cases. When
any description changed, include every skill's must-not-run cases:
descriptions compete.

## 7. Report

- The skill's files, created or changed, and its links.
- **Eval cases:** the cases written; or, without an eval setup, each case
  you would write, with its prompt and what it grades, including one for
  each "Do not use for" item.
- What `test-skill` reported in the last round, and the eval scores if
  they ran.
- What you decided in "Settle the shape" without asking, so the user can
  correct it.

Do not commit.
