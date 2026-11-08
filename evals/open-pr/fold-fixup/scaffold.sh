# A finished branch with a local fixup commit left over.
. "$(dirname "$0")/../fixture.sh"

work_commit
cat >>test/label.test.js <<'EOF'

test("keeps widgets without a unit", () => {
  assert.strictEqual(formatLabel("Probes", 2), "Probes: 2 widgets");
});
EOF
git add -A
git commit -q -m "fixup! feat: name the unit in widget labels"

finish_fixture
