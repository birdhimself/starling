# Shared setup for the evals of the issue skills (implement-issue,
# refine-draft-issues, triage-issue), sourced by each case's scaffold.sh.
# claude plugin eval runs a scaffold with bash, in the run's working
# directory, with a fresh HOME.
#
# Builds a small project with an installed copy of .starling/, an AGENTS.md
# that imports the shared rules, a policy file for each issue skill, and an
# origin remote with main pushed. The remote is a local repository, not
# GitHub, so every gh call fails: the cases grade the commands the agent
# runs and what it reports, not their effect on GitHub.

set -eu
starling=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)

git init -q -b main
git config user.name "Eval User"
git config user.email eval@example.com

cp -R "$starling/.starling" .starling
echo v0.0.0 >.starling/VERSION

mkdir -p lib test lib/legacy .agents/policy

cat >AGENTS.md <<'EOF'
# widgets

This repository also follows the shared rules in Starling; read them before starting any task: @.starling/AGENTS.md

Formats the labels of the widgets dashboard.

- `lib/`: the library. `test/`: the tests, run with `npm test`.
- `lib/legacy/`: the old formatter, still imported by other dashboards.
EOF

cat >package.json <<'EOF'
{
  "name": "widgets",
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

cat >lib/legacy/label.js <<'EOF'
// The old formatter. Other dashboards import it; keep its output stable.
module.exports = (name, count) => name + " (" + count + ")";
EOF

cat >test/label.test.js <<'EOF'
const test = require("node:test");
const assert = require("node:assert");
const { formatLabel } = require("../lib/label");

test("counts the widgets", () => {
  assert.strictEqual(formatLabel("Sensors", 3), "Sensors: 3 widgets");
});
EOF

cat >.agents/policy/triage-issue.md <<'EOF'
# Issue metadata

Every issue gets exactly one issue type and exactly one `area::*` label.

Types:

- `Bug`: behavior that does not work as intended
- `Feature`: a new or improved capability
- `Technical`: tooling, build, CI and maintenance

Areas:

- `area::labels`: how widget labels are formatted
- `area::lobby`: hosting, joining and leaving a lobby
- `area::infra`: build, CI and tooling

The Priority field, id 4711, takes `High`, `Medium` or `Low`, and only when
someone decided the priority.

The `draft` label marks an issue that is not ready to implement.
EOF

cat >.agents/policy/implement-issue.md <<'EOF'
# Implementing issues

- Validate every change with `npm test`.
- Changes to `lib/legacy/` need the maintainer's agreement before they
  start: other dashboards import it.
EOF

cat >.agents/policy/refine-draft-issues.md <<'EOF'
# Refining issues

- Every refined body also has a **Rollout** section: whether the change
  needs an announcement on the dashboard, and why.
- Propose `npm test` as the validation for library changes.
EOF

git add -A
git commit -q -F - <<'EOF'
feat: format widget labels

The dashboard shows each widget group with its name and how many
widgets it holds.
EOF

git init -q --bare .git/eval-origin.git
git remote add origin "$PWD/.git/eval-origin.git"
git push -q -u origin main 2>/dev/null
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

finish_fixture() {
	: >.git/logs/HEAD
	rm -f .git/COMMIT_EDITMSG
}
