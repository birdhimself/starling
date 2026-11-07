# Two unrelated changes: a bug fix with its test, and a typo in the README.
. "$(dirname "$0")/../fixture.sh"

cat >lib/label.js <<'JS'
// Formats the label shown for a group of widgets.
function formatLabel(name, count) {
  const noun = count === 1 ? "widget" : "widgets";
  return `${name}: ${count} ${noun}`;
}

module.exports = { formatLabel };
JS
cat >>test/label.test.js <<'JS'

test("uses the singular for one widget", () => {
  assert.strictEqual(formatLabel("Sensors", 1), "Sensors: 1 widget");
});
JS
sed 's/dashbaord/dashboard/' README.md >README.md.new && mv README.md.new README.md

finish_fixture
