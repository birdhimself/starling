# A clean project skill with one eval case: the evals must wait for the
# user's answer.
. "$(dirname "$0")/../fixture.sh"

write_skill 'Reviews how the dashboard formats widget labels and reports labels that read wrong, without changing code. Use when asked to review or check widget labels. Do not use for changing labels or for reviewing other code.'
mkdir -p .claude-plugin evals/review-labels/one-widget
cat >.claude-plugin/plugin.json <<'JSON'
{
  "name": "labels",
  "description": "This repository's own skills, loaded as a plugin only to run their evals.",
  "skills": "./.agents/skills"
}
JSON
cat >evals/review-labels/one-widget/case.yaml <<'YAML'
schema_version: "1.1"
name: review-labels-one-widget
description: >-
  The review finds that a single widget is labeled "1 widgets".
tags: [review-labels]
execution:
  prompt: >-
    Review the widget labels.
  max_turns: 10
runs: 3
graders:
  - name: uses-the-skill
    type: tool_used
    tool: Skill
    input_match: review-labels
YAML

finish_fixture
