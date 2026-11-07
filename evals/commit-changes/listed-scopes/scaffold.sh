# A bug fix in lib/ in a repository that lists the scopes cli and lib.
. "$(dirname "$0")/../fixture.sh"

printf '[commit]\n\tscopes = cli lib\n' >.starling.conf
commit_files 'build: list the commit scopes

Commits name the part of the project they change: lib for the library,
cli for the command line tool.'
git push -q 2>/dev/null

cat >lib/label.js <<'JS'
// Formats the label shown for a group of widgets.
function formatLabel(name, count) {
  const noun = count === 1 ? "widget" : "widgets";
  return `${name}: ${count} ${noun}`;
}

module.exports = { formatLabel };
JS

finish_fixture
