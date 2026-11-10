# The same project before Starling was installed into it.
. "$(dirname "$0")/../fixture.sh"

rm -r .starling
grep -v '@\.starling/AGENTS\.md$' AGENTS.md | cat -s >AGENTS.md.new
mv AGENTS.md.new AGENTS.md
finish_fixture
