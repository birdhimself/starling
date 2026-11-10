# Shared setup for the adopt-starling evals, sourced by each case's
# scaffold.sh. claude plugin eval runs a scaffold with bash, in the run's
# working directory, with a fresh HOME.
#
# Builds a small project that had its own agent setup before Starling was
# installed into it: a create-pr skill that Starling's open-pr skill
# replaces, with a label and a check of the project's own; a review-labels
# skill that Starling has no twin for; and an AGENTS.md with a rule the
# shared rules repeat and one the commit check contradicts. The create-pr
# skill is in .agents/skills/ without a link, because the runner's sandbox
# sometimes refuses to remove files in .claude/. The eval runner loads only
# the plugin under test, so Starling's skills come from there and are not
# linked. Each scaffold then sets up its case and calls finish_fixture.

set -eu
starling=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)

git init -q -b main
git config user.name "Eval User"
git config user.email eval@example.com

cp -R "$starling/.starling" .starling
echo v0.0.0 >.starling/VERSION

mkdir -p lib test .claude/skills .agents/skills/create-pr .agents/skills/review-labels
cp .starling/claude-settings.json .claude/settings.json

cat >AGENTS.md <<'MD'
# labels

This repository also follows the shared rules in Starling; read them before starting any task: @.starling/AGENTS.md

Formats the labels of the widgets dashboard.

- `lib/`: the library. `test/`: the tests, run with `npm test`.
- Never commit with `--no-verify`.
- Commit messages follow Conventional Commits. Use `chore:` for anything
  that is neither a feature nor a fix.
- Open pull requests with the create-pr skill.
MD

cat >package.json <<'MD'
{
  "name": "labels",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "lint": "node --check lib/label.js",
    "test": "node --test"
  }
}
MD

cat >lib/label.js <<'MD'
// Formats the label shown for a group of widgets.
function formatLabel(name, count) {
  return `${name}: ${count} widgets`;
}

module.exports = { formatLabel };
MD

cat >test/label.test.js <<'MD'
const test = require("node:test");
const assert = require("node:assert");
const { formatLabel } = require("../lib/label");

test("counts the widgets", () => {
  assert.strictEqual(formatLabel("Sensors", 3), "Sensors: 3 widgets");
});
MD

cat >.agents/skills/create-pr/SKILL.md <<'MD'
---
name: create-pr
description: Creates a pull request for the current branch. Use when asked to open, create or send a pull request.
---

# Create a pull request

1. Run `npm test` and `npm run lint`. Stop if either fails.
2. Push the branch: `git push -u origin HEAD`.
3. Create the pull request as a draft, with a plain sentence as its title
   and a body that says what changed and how it was tested:
   `gh pr create --draft --label dashboard`.

Every pull request in this repository carries the `dashboard` label,
which the release notes are built from.
MD

cat >.agents/skills/review-labels/SKILL.md <<'MD'
---
name: review-labels
description: Reviews how the dashboard formats widget labels and reports labels that read wrong, without changing anything. Use when asked to review or check widget labels. Do not use for fixing a label.
---

# Review labels

Find where labels are formatted with `git grep -n formatLabel`, then check
each call site for a label that would read wrong, such as "1 widgets".
Report the call sites and what is wrong with each. Change nothing.
MD
ln -s ../../.agents/skills/review-labels .claude/skills/review-labels

finish_fixture() {
	git add -A
	git commit -q -m "feat: format widget labels" -m "The dashboard shows each group with its widget count."
}
