# A branch with uncommitted work.
. "$(dirname "$0")/../fixture.sh"

git switch -q --no-track -c feat/12-unit-labels origin/main
sed -i.bak 's/widgets`/items`/' lib/label.js && rm lib/label.js.bak

finish_fixture
