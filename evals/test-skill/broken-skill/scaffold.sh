# A project skill that breaks three rules: no "Do not use for" in its
# description, a hard-coded repository, and a command named .sh.
. "$(dirname "$0")/../fixture.sh"

write_skill 'Reviews how the dashboard formats widget labels. Use when asked to review widget labels.'
cat >>.agents/skills/review-labels/SKILL.md <<'MD'

Open label bugs are listed by `gh api repos/acme/labels/issues`.
MD
cat >.agents/skills/review-labels/scripts/count.sh <<'SH'
#!/bin/sh
grep -rc formatLabel lib
SH
chmod +x .agents/skills/review-labels/scripts/count.sh

finish_fixture
