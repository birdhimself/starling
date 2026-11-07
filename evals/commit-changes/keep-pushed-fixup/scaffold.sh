# A fix for a commit on this branch that is already pushed.
. "$(dirname "$0")/../fixture.sh"

git checkout -q -b label-units
write_unit_label unti
commit_files 'feat: show the unit in widget labels

Groups that hold other things than widgets, such as sensors, can now
name their unit. Labels keep saying widgets when no unit is given.'
git push -q -u origin label-units 2>/dev/null
write_unit_label unit

finish_fixture
