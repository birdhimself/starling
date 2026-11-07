# The last commit on the branch, never pushed, has a message the check
# rejects.
. "$(dirname "$0")/../fixture.sh"

git checkout -q -b label-units
write_unit_label unit
commit_files 'Updated the label code'

finish_fixture
