# Shared setup for the clean-merged-branches evals, sourced by each case's
# scaffold.sh. claude plugin eval runs a scaffold with bash, in the run's
# working directory, with a fresh HOME.
#
# Builds a small project with an installed copy of .starling/, on main, with
# four local branches: old-fix, fully contained in main; rebased-feature,
# whose patch is on main under another commit; and wip-lobby and
# backup/pre-squash, with commits that are not.

set -eu
starling=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)

git init -q -b main
git config user.name "Eval User"
git config user.email eval@example.com

cp -R "$starling/.starling" .starling
echo v0.0.0 >.starling/VERSION

cat >AGENTS.md <<'EOF'
# widgets

This repository also follows the shared rules in Starling; read them before starting any task: @.starling/AGENTS.md
EOF

note() { # FILE MESSAGE
	echo "$2" >>"$1"
	git add -A
	git commit -q -m "$2" -m "A change for the fixture."
}

git add -A
git commit -q -m "feat: start the project" -m "The first commit."
note a.txt "fix: correct the first label"
git branch old-fix

git switch -q -c rebased-feature
note feature.txt "feat: add the feature"
git switch -q -c wip-lobby main
note lobby.txt "feat: start the lobby"
git switch -q -c backup/pre-squash main
note backup.txt "feat: history from before a squash"

git switch -q main
note b.txt "fix: correct the second label"
git cherry-pick rebased-feature >/dev/null

git init -q --bare .git/eval-origin.git
git remote add origin "$PWD/.git/eval-origin.git"
git push -q -u origin main 2>/dev/null
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
