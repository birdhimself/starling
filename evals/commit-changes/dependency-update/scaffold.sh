# A dependency update in a repository without scopes.
. "$(dirname "$0")/../fixture.sh"

sed 's/"\^1\.2\.0"/"^1.3.0"/' package.json >package.json.new && mv package.json.new package.json
sed 's/"\^1\.2\.0"/"^1.3.0"/; s/left-pad-1\.2\.0/left-pad-1.3.0/; s/"version": "1\.2\.0"/"version": "1.3.0"/' \
	package-lock.json >package-lock.json.new && mv package-lock.json.new package-lock.json

finish_fixture
