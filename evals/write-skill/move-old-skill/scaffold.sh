# A project skill still in .claude/skills/, whose description says nothing
# about the requests it must not take.
. "$(dirname "$0")/../fixture.sh"

mkdir -p .claude/skills/review-labels
cat >.claude/skills/review-labels/SKILL.md <<'MD'
---
name: review-labels
description: Reviews how the dashboard formats widget labels and reports labels that read wrong. Use when asked about widget labels.
---

# Review labels

Find where labels are formatted with `git grep -n formatLabel`, then check
each call site for a label that would read wrong, such as "1 widgets".
Report the call sites and what is wrong with each. Change nothing.
MD

finish_fixture
