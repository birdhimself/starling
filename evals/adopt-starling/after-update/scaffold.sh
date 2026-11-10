# The committed Starling had no open-pr skill; an update that is not
# committed yet brought it.
. "$(dirname "$0")/../fixture.sh"

rm -r .starling/skills/open-pr
finish_fixture
cp -R "$starling/.starling/skills/open-pr" .starling/skills/open-pr
echo v0.0.1 >.starling/VERSION
