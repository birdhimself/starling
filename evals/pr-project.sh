# Shared setup for the evals of the pull request skills (finish-pr,
# apply-review-findings, resolve-review-threads, ship-issue,
# ship-issue-batch), sourced by each case's scaffold.sh after the widgets
# project of issue-project.sh.
#
# Adds a command line tool and the branch of pull request #7,
# fix/12-singular-label, pushed to the local origin. Its commit makes a
# label for one widget read "1 widget", with a test, but the command line
# tool passes the count as a string, so it still prints "1 widgets": a
# defect a reviewer can find. GitHub is out of reach, so gh fails.

. "$(dirname -- "$0")/../../issue-project.sh"

mkdir -p cli
cat >cli/main.js <<'EOF'
const { formatLabel } = require("../lib/label");

const [name = "All", count = "0"] = process.argv.slice(2);
console.log(formatLabel(name, count));
EOF
git add cli
git commit -q -m "feat: print a label from the command line" -m "The tool takes a group name and a count and prints the label."
git push -q origin main 2>/dev/null

git switch -q -c fix/12-singular-label
cat >lib/label.js <<'EOF'
// Formats the label shown for a group of widgets.
function formatLabel(name, count) {
  const noun = count === 1 ? "widget" : "widgets";
  return `${name}: ${count} ${noun}`;
}

module.exports = { formatLabel };
EOF
cat >>test/label.test.js <<'EOF'

test("uses the singular for one widget", () => {
  assert.strictEqual(formatLabel("Sensors", 1), "Sensors: 1 widget");
});
EOF
git add -A
git commit -q -F - <<'EOF'
fix: use the singular in a label for one widget

A group with exactly one widget was labeled "1 widgets", because the
label always used the plural.

The label now uses "widget" for a count of one.

Refs: #12
EOF
git push -q -u origin fix/12-singular-label 2>/dev/null
