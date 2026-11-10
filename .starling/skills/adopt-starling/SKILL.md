---
name: adopt-starling
description: Fits a repository to the Starling installed in it, after an install or an update. It compares the repository's own skills, agent instructions, hooks and commit scopes with what Starling brings, proposes which skills Starling replaces, which policy files keep what is specific to the repository, which lines leave AGENTS.md and what else is left over, and writes the confirmed changes. Ends at changed files, never committed. Use when asked to adopt, set up, migrate to or finish installing Starling in a repository, to move a repository's skills or rules over to Starling's, or to check what an install or update of Starling replaces, duplicates or makes redundant in the repository. Do not use for installing or updating Starling itself, which its install and update scripts do, for creating or changing one skill (use `write-skill`), for editing AGENTS.md for any other reason, or for committing the result (use `commit-changes`).
---

# Adopt Starling

The installer copies Starling into a repository and links its skills. It
cannot judge what the repository already had: skills that now have a twin,
rules that the shared rules repeat or contradict, hooks another tool ran.
Compare the two, propose every change in one round, and write only what
the user confirms. Paths are relative to the repository root.

## Contract

- **Input:** a repository with Starling installed, right after an install
  or an update, or at any later time. A caller may narrow the work, such
  as to the skills only.
- **Output:** the confirmed changes in the working tree, not committed:
  replaced skills removed, policy files written, `AGENTS.md` trimmed,
  scopes in `.starling.conf`, leftovers settled; and a report.
- **Entry points:** a caller who brings the user's confirmed list of
  changes starts at "Write the confirmed changes", after the survey.
- **Never:** change anything in `.starling/`; remove or change a skill, a
  line of `AGENTS.md`, a hook or a dependency the user did not confirm;
  put into a policy file what the repository did not already say; install
  or update Starling; commit.

## 1. Survey

Without `.starling/VERSION`, stop: see the stop conditions. Otherwise run:

```sh
.starling/skills/adopt-starling/scripts/survey
```

It only reads, and prints the facts: the installed version and whether an
update brought new skills, the repository's own skills, name clashes,
Starling's skills, which of them read a policy file and what it may hold,
the instruction files, the hooks, other commit checks, the scopes, the
Claude Code settings and Renovate.

After an update, `New skills:` names what to compare first, but go
through everything: a skill that existed before may have grown to cover
one of the repository's.

Then read what the survey names, in full: each of the repository's own
skills with its reference files and scripts, every `AGENTS.md` and
`CLAUDE.md`, the hook files, and each of Starling's skills that one of
the repository's might overlap.

## 2. Sort the repository's own skills

Give each one exactly one verdict:

- **Replace:** one of Starling's skills does the same job, so the same
  request would load both. The skill goes. What it says about this
  repository and Starling's skill does not, such as a label, a check
  command or a reviewer, moves to that skill's policy file or, when
  Starling's skill reads none, to `AGENTS.md`.
- **Keep:** no skill of Starling's does its job. Leave it as it is. When
  it is still a real directory in `.claude/skills/` or its name clashes
  with one of Starling's, say that the `write-skill` skill moves or
  renames it; do not do that here.
- **Split:** part of it is one of Starling's skills and part is not.
  Propose what to cut, and leave the cutting to the `write-skill` skill.

A name clash is settled the same way: the repository's skill is replaced,
or it is kept and renamed. For every skill to replace, find its callers
with `git grep -n <name>`: other skills, `AGENTS.md`, documentation and
scripts that name it then name Starling's skill.

## 3. Draft the policy files

For each of Starling's skills, collect what the repository says that
matters only while that skill runs: from the skills it replaces, and from
lines of `AGENTS.md` that concern only that work. The survey prints what
each policy file may hold.

- Write the repository's rules and the commands they need, not steps: the
  skill has the steps.
- Take only what the repository states. Never fill a policy with what
  seems sensible, and leave out what repeats the skill's own default.
- A policy cannot lift a skill's contract. When an old skill did what
  Starling's must never do, such as merging, say so in the proposal as
  something that is lost, and do not write it down as policy.
- Add to a policy file that exists; do not rewrite it.
- Plain Markdown, no frontmatter, named `.agents/policy/<skill>.md`.

## 4. Go through the instructions

Compare each `AGENTS.md` with the shared rules. For lines about commit
messages, read the format in the `commit-changes` skill first: the commit
check enforces it, so a line that asks for a type, a scope or a trailer
the format does not have, such as `chore`, contradicts it.

- A line that repeats a shared rule goes.
- A line that contradicts one needs a decision: a repository may refine
  the shared rules, but what the commit check enforces cannot be refined
  away, and a commit that follows such a line is rejected. Name the
  contradiction, and propose removing or changing the line.
- A line that matters to one skill only moves to that skill's policy.
- A mention of a skill to replace becomes Starling's skill.
- A `CLAUDE.md` next to `AGENTS.md` is merged into `AGENTS.md`.

Everything else stays word for word: this is not a rewrite.

## 5. Settle the scopes and the leftovers

- **Scopes:** when the history uses scopes that name parts of the project
  and `.starling.conf` does not allow them, propose the list as
  `[commit]` `scopes = ...`. Leave out scopes used once or twice and
  scopes such as `deps` that name no part of the code unless the user
  wants them. With no scopes in the history, propose none.
- **Hooks:** a hook of another tool moves to `.githooks/<name>`,
  executable, where Starling's hooks run it. Drop a `commit-msg` hook
  that only runs another message check. Once nothing is left for the
  other tool, removing it is a change to the project's dependencies:
  propose the command, and after it
  `git config --unset core.hooksPath && .starling/bin/activate-hooks`.
- **Other commit checks:** Starling's checker replaces commitlint.
  Propose removing its configuration and its dependency.
- **Settings and Renovate:** when the survey says the settings lack
  Starling's hooks or Renovate needs a rule, propose that edit.

## 6. Propose

Show everything in one message and wait:

- each of the repository's skills with its verdict and the reason, and
  for one to replace, the skill of Starling's that takes over, what moves
  where, and what is lost;
- each policy file, with its full text;
- each change to `AGENTS.md`, as the lines that go or change;
- the scopes, the hooks and the other leftovers;
- what stays as it is.

"Adopt Starling" is a request for this proposal, not permission to carry
it out. The user may confirm all of it, parts of it, or change it.

## 7. Write the confirmed changes

Only what was confirmed, exactly as confirmed:

- Remove a replaced skill's directory and every link to it. When the
  clash kept Starling's skill of that name from being linked, link it:
  `ln -s ../../.starling/skills/<name> .claude/skills/<name>`, and the
  same in `.agents/skills/`.
- Write the policy files, the changes to `AGENTS.md` and its callers, and
  `.starling.conf`.
- Move the hooks, and run the commands the user confirmed.

Sandboxes often refuse writes in `.claude/`. When removing a skill or a
link there fails, do not work around it: give the user the command to
run, and say in the report that the skill is still there.

Run the survey again: no clash is left, and every policy file is named
after a skill that reads it. Do not commit.

## 8. Report

- What changed: skills removed, policy files written, lines changed.
- What stays, and what is left for the user, such as a skill to split or
  rename with the `write-skill` skill.
- What was lost on purpose, such as a step of an old skill that
  Starling's skill does not take.
- How to commit it with the `commit-changes` skill: an install or update
  the survey calls "not committed yet" first, alone, with the header the
  installer printed, then these changes.

## Stop conditions

- Starling is not installed (no `.starling/` folder) → stop, and give the
  install command from Starling's README:
  `curl -fsSL https://raw.githubusercontent.com/birdhimself/starling/main/install | sh`.
  Do not run it unless the user asks.
- This is Starling's own repository (`.starling/skills/` without
  `.starling/VERSION`) → stop: there is nothing to adopt.
- A rule of the repository contradicts a shared rule and nothing settles
  which holds → ask in the proposal; do not pick.
- Nothing is confirmed → change nothing.
