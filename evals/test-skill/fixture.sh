# Shared setup for the test-skill evals, sourced by each case's scaffold.sh.
# claude plugin eval runs a scaffold with bash, in the run's working
# directory, with a fresh HOME.
#
# Builds a small project with a copy of .starling/ and one project skill,
# review-labels, in .agents/skills/ with a link from .claude/skills/. The
# eval runner loads only the plugin under test, so the project skill is
# files to test, never a loaded skill. Each scaffold then sets up its case
# and calls finish_fixture.

set -eu
starling=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)

git init -q -b main
git config user.name "Eval User"
git config user.email eval@example.com

cp -R "$starling/.starling" .starling
echo v0.0.0 >.starling/VERSION

mkdir -p lib test .agents/skills/review-labels/scripts .claude/skills
ln -s ../../.agents/skills/review-labels .claude/skills/review-labels

cat >AGENTS.md <<'EOF'
# labels

Formats the labels of the widgets dashboard.

- `lib/`: the library. `test/`: the tests, run with `npm test`.
- `.agents/skills/`: this repository's own skills.
EOF

cat >package.json <<'EOF'
{
  "name": "labels",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node --test"
  }
}
EOF

cat >lib/label.js <<'EOF'
// Formats the label shown for a group of widgets.
function formatLabel(name, count) {
  return `${name}: ${count} widgets`;
}

module.exports = { formatLabel };
EOF

cat >test/label.test.js <<'EOF'
const test = require("node:test");
const assert = require("node:assert");
const { formatLabel } = require("../lib/label");

test("counts the widgets", () => {
  assert.strictEqual(formatLabel("Sensors", 3), "Sensors: 3 widgets");
});
EOF

# write_skill DESCRIPTION: the project skill, with a script that lists the
# labels' call sites.
write_skill() {
	cat >.agents/skills/review-labels/SKILL.md <<EOF
---
name: review-labels
description: $1
---

# Review labels

Run \`scripts/call-sites\` to list where labels are formatted, then check
each call site for a label that would read wrong, such as "1 widgets".
Report the call sites and what is wrong with each. Change nothing.
EOF
	cat >.agents/skills/review-labels/scripts/call-sites <<'EOF'
#!/bin/sh
# Lists the lines that format a label.
grep -rn formatLabel lib test
EOF
	chmod +x .agents/skills/review-labels/scripts/call-sites
}

finish_fixture() {
	git add -A
	git commit -q -m "feat: format widget labels" -m "The dashboard shows each group with its widget count."
}
