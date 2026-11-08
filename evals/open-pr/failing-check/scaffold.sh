# A branch whose last change left a test failing.
. "$(dirname "$0")/../fixture.sh"

work_commit
cat >>test/label.test.js <<'EOF'

test("uses the singular for one", () => {
  assert.strictEqual(formatLabel("Probes", 1, "sensors"), "Probes: 1 sensor");
});
EOF
git add -A
git commit -q --amend --no-edit

finish_fixture
