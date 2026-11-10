# The adoption's changes are in the working tree, ready to commit.
. "$(dirname "$0")/../fixture.sh"

finish_fixture
rm -r .agents/skills/create-pr
mkdir -p .agents/policy
cat >.agents/policy/open-pr.md <<'MD'
# Pull requests

- Run `npm test` and `npm run lint` before opening a pull request.
- Every pull request carries the `dashboard` label, which the release
  notes are built from.
MD
sed -i.bak 's/create-pr skill/open-pr skill/' AGENTS.md && rm AGENTS.md.bak
