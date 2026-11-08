# Shared setup for open-pr's cases, sourced by each case's scaffold.sh after
# the widgets project of issue-project.sh. The remote is a local repository,
# so pushes work and every gh call fails.

. "$(dirname -- "$0")/../../issue-project.sh"

cat >.agents/policy/open-pr.md <<'EOF'
# Opening pull requests

- Validate with `npm test`.
- `gh` signs in on demand in this repository, so it may say it is logged
  out. Run `git push` and `gh pr create` or `gh pr edit` anyway, and report
  any error they give.
EOF
git add -A
git commit -q -m "docs: add the policy for opening pull requests" -m "Agents should try the commands, because gh signs in on demand."
git push -q origin main 2>/dev/null

# add_template: commit a pull request template to main and push it.
add_template() {
	mkdir -p .github
	cat >.github/pull_request_template.md <<'EOF'
<!-- Title: a plain sentence. -->

## Changes

<!-- What changes and why. -->

## Rollout

<!-- What must happen when this ships, or "None". -->

## Validation

- [ ] `npm test`
- [ ] Checked on a staging dashboard
EOF
	git add -A
	git commit -q -m "docs: add a pull request template" -m "Pull requests should say how a change rolls out."
	git push -q origin main 2>/dev/null
}

# work_commit [BRANCH]: commit a finished change, on a new branch by default.
work_commit() {
	branch=${1:-feat/12-unit-labels}
	[ "$branch" = main ] || git switch -q --no-track -c "$branch" origin/main
	cat >lib/label.js <<'EOF'
// Formats the label shown for a group of widgets.
function formatLabel(name, count, unit = "widgets") {
  return `${name}: ${count} ${unit}`;
}

module.exports = { formatLabel };
EOF
	cat >>test/label.test.js <<'EOF'

test("names the unit", () => {
  assert.strictEqual(formatLabel("Probes", 2, "sensors"), "Probes: 2 sensors");
});
EOF
	git add -A
	git commit -q -F - <<'EOF'
feat: name the unit in widget labels

Groups that hold other things than widgets could only be labeled as
widgets.

A label now takes an optional unit, and keeps saying widgets without
one.

Refs: #12
EOF
}
