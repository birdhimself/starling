# A pushed branch with an open pull request.
. "$(dirname "$0")/../fixture.sh"

work_commit
git push -q -u origin feat/12-unit-labels 2>/dev/null

finish_fixture
