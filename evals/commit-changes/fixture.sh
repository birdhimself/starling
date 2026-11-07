# Shared setup for the commit-changes evals, sourced by each case's
# scaffold.sh. claude plugin eval runs a scaffold with bash, in the run's
# working directory, with a fresh HOME.
#
# Builds a small project with a copy of .starling/ and an origin remote with
# main pushed. The skill itself comes from the plugin under test (the
# repository root's .claude-plugin/plugin.json): the eval runner loads no
# project skills, and leaving out the .claude/skills links keeps the skill
# out of any baseline run. Each scaffold then sets up its case and calls
# finish_fixture.
#
# Graders cannot run commands after a run, and the eval runner turns off all
# git hooks, so they read what git writes on its own: .git/logs/HEAD gets a
# line for every commit, amend and rebase step ("commit: <subject>",
# "commit (amend): ...", "rebase (fixup): ..."), and .git/COMMIT_EDITMSG
# holds the last commit's full message. finish_fixture empties both, so they
# show only what the agent did. With hooks off, the skill's own run of the
# checker is the only check.

set -eu
starling=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)

git init -q -b main
git config user.name "Eval User"
git config user.email eval@example.com

cp -R "$starling/.starling" .starling

mkdir -p lib cli test

cat >AGENTS.md <<'EOF'
# widgets

Formats the labels of the widgets dashboard.

- `lib/`: the library. `cli/`: the command line tool. `test/`: the tests.
- Run the tests with `npm test`.
EOF

cat >README.md <<'EOF'
# widgets

Formats the labels shown on the widgets dashbaord.

Run the tests with `npm test`.
EOF

cat >package.json <<'EOF'
{
  "name": "widgets",
  "version": "1.4.0",
  "private": true,
  "scripts": {
    "test": "node --test"
  },
  "dependencies": {
    "left-pad": "^1.2.0"
  }
}
EOF

cat >package-lock.json <<'EOF'
{
  "name": "widgets",
  "version": "1.4.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "widgets",
      "version": "1.4.0",
      "dependencies": {
        "left-pad": "^1.2.0"
      }
    },
    "node_modules/left-pad": {
      "version": "1.2.0",
      "resolved": "https://registry.npmjs.org/left-pad/-/left-pad-1.2.0.tgz",
      "license": "WTFPL"
    }
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

cat >cli/main.js <<'EOF'
const leftPad = require("left-pad");
const { formatLabel } = require("../lib/label");

const [name = "All", count = "0"] = process.argv.slice(2);
console.log(leftPad(formatLabel(name, Number(count)), 40));
EOF

cat >test/label.test.js <<'EOF'
const test = require("node:test");
const assert = require("node:assert");
const { formatLabel } = require("../lib/label");

test("counts the widgets", () => {
  assert.strictEqual(formatLabel("Sensors", 3), "Sensors: 3 widgets");
});
EOF

git add -A
git commit -q -F - <<'EOF'
feat: format widget labels

The dashboard shows each widget group with its name and how many
widgets it holds. The command line tool prints the same label.
EOF

git init -q --bare .git/eval-origin.git
git remote add origin "$PWD/.git/eval-origin.git"
git push -q -u origin main 2>/dev/null
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

# commit_files MESSAGE: commit everything with that message, before the
# logger is installed.
commit_files() {
	git add -A
	printf '%s\n' "$1" | git commit -q -F -
}

# The unit change used by the branch cases. $1 is the variable name the
# template uses, so a case can start from a buggy version.
write_unit_label() {
	cat >lib/label.js <<EOF
// Formats the label shown for a group of widgets.
function formatLabel(name, count, unit = "widgets") {
  return \`\${name}: \${count} \${$1}\`;
}

module.exports = { formatLabel };
EOF
}

finish_fixture() {
	: >.git/logs/HEAD
	rm -f .git/COMMIT_EDITMSG
}
