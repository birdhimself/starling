# The widgets project with pull request #7's branch; GitHub is out of reach.
. "$(dirname "$0")/../../pr-project.sh"

cat >>test/label.test.js <<'EOF'

test("keeps the plural for two widgets", () => {
  assert.strictEqual(formatLabel("Sensors", 2), "Sensors: 2 widgets");
});
EOF
git add -A
git commit -q -m "fixup! fix: use the singular in a label for one widget"
git push -q origin fix/12-singular-label 2>/dev/null

finish_fixture
