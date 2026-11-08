# Shared setup for the write-skill evals, sourced by each case's scaffold.sh.
# claude plugin eval runs a scaffold with bash, in the run's working
# directory, with a fresh HOME.
#
# Builds a small project with an installed copy of .starling/ and an
# AGENTS.md that imports the shared rules. The eval runner loads only the
# plugin under test, so Starling's skills come from there; the project's
# own skills are files. Each scaffold then sets up its case and calls
# finish_fixture.

set -eu
starling=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)

git init -q -b main
git config user.name "Eval User"
git config user.email eval@example.com

cp -R "$starling/.starling" .starling
echo v0.0.0 >.starling/VERSION

mkdir -p lib test

cat >AGENTS.md <<'EOF'
# labels

This repository also follows the shared rules in Starling; read them before starting any task: @.starling/AGENTS.md

Formats the labels of the widgets dashboard.

- `lib/`: the library. `test/`: the tests, run with `npm test`.
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

# eval_setup: a plugin manifest that loads the project's own skills, so the
# project can run eval cases.
eval_setup() {
	mkdir -p .claude-plugin evals
	cat >.claude-plugin/plugin.json <<'EOF'
{
  "name": "labels",
  "description": "This repository's own skills, loaded as a plugin only to run their evals.",
  "skills": "./.agents/skills"
}
EOF
	printf 'evals/results/\n' >.gitignore
	touch evals/.gitkeep
}

finish_fixture() {
	git add -A
	git commit -q -m "feat: format widget labels" -m "The dashboard shows each group with its widget count."
}
