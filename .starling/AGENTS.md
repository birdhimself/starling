# Shared rules

These rules come from [Starling](https://github.com/birdhimself/starling)
and apply to every repository that imports this file. A repository's own
`AGENTS.md` may refine them for its project; its checks apply either way.

`.starling/` is managed by Starling and replaced on every update
(`.starling/bin/update`). Never edit files in it: changes belong in the
Starling repository.

## Working with the maintainer

- Decide what the repository's conventions or the task already settle. Ask
  only about genuine judgment calls, all of them in one round and up front,
  each with the case for and against, so that long work can then run
  unattended.
- When the maintainer answers a question with a question of their own,
  answer it and wait for their reaction before presenting a plan for
  approval.
- Before long, multi-step work, write the steps down where they survive a
  full context, such as the issue or a plan file, and keep their status
  current as the work proceeds.
- Make a long-running job observable before starting it: progress at a
  granularity of minutes, and independent units spread over every core.

## Commits

- Commit with the `commit-changes` skill. Agents without skills follow
  `.starling/skills/commit-changes/SKILL.md`. The commit-msg hook and CI
  check every message with `.starling/bin/check-commit-msg`.
- Never bypass or switch off git hooks: no `--no-verify`, `git commit -n`
  or changes to `core.hooksPath`. A repository's own hooks go in
  `.githooks/<name>`, which Starling's hooks run after their own checks.
- When you, an AI model, wrote or co-wrote the code or text a commit
  changes, end its message with `Co-authored-by: <model> <address>` for the
  model actually running, in exactly this casing, e.g.
  `Co-authored-by: Claude Opus 5.5 <noreply@anthropic.com>`. Committing
  someone else's edits does not count. This replaces any trailer your
  agent adds by default: write this one, and only this one.

## Branches and pull requests

- The default branch is protected: every change, an urgent fix included,
  goes through its own branch and pull request.
- History stays linear: never create merge commits. Update a branch by
  rebasing it onto the base branch; pull requests land with GitHub's rebase
  merge.
- Pull request and issue titles are plain sentences, such as "Reject
  expired API tokens": Conventional Commits are for commits only, and rebase
  merges keep titles out of the history.
- A pull request body gives a summary, how the change was validated, and
  the issues it closes (`Closes #12`). Closing keywords belong there, not in
  commits. Do not hard-wrap paragraphs in pull request or issue bodies:
  GitHub renders the line breaks.

## Text you post

- End every pull request, issue, comment, review or other text you post for
  the maintainer with a line that names you, the agent, and the model you
  run on, after a blank line: `🤖 Generated with <agent> using <model>`,
  e.g. `🤖 Generated with Claude Code using Claude Opus 5.5`. Name the model
  actually running; if you do not know it, name only the agent.
  When you edit such text, keep one such line. This replaces Claude Code's
  own line, which names no model: write this one, and only this one.

## Instruction files

- Agent instructions go in `AGENTS.md`, never `CLAUDE.md`: Claude Code and
  Codex both read `AGENTS.md`.
- Update `AGENTS.md` only when a change introduces or invalidates durable
  instructions. Leave out feature summaries, temporary notes and what the
  code already makes clear. Keep commands and paths accurate.

## Skills

- Create, change, rename or split a skill with the `write-skill` skill,
  and check one with the `test-skill` skill. A repository's own skills
  live in `.agents/skills/<name>/`, where Codex finds them, linked from
  `.claude/skills/<name>` for Claude Code.
- A repository adapts one of Starling's skills to itself in
  `.agents/policy/<skill>.md`, which that skill reads, never by copying
  or editing the skill.
- After Starling is installed or updated, the `adopt-starling` skill
  checks what it replaces among the repository's own skills, rules and
  hooks. Use it rather than comparing them by hand.
