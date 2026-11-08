---
name: refine-draft-issues
description: Refines GitHub issues that are not ready to implement, labeled draft by default, into implementation-ready scope, acceptance criteria and validation, sets their type, labels and relationships through triage-issue, and takes the draft label off only once nothing is left to decide. Shows every change and waits for confirmation before writing. Use when asked to refine, groom, flesh out, tighten or unblock draft issues, or to make a vague issue ready to work on. Do not use for creating issues, for relabeling or linking issues that are not drafts (use `triage-issue`), for closing or deduplicating issues, for implementing an issue (use `implement-issue`), or for writing pull request descriptions.
argument-hint: "[issue]..."
---

# Refine draft issues

Turn unready issues into issues an implementer can pick up without asking
a follow-up question. Never invent a product decision to make an issue
look finished: an open question, written down, is a good outcome.

## Contract

- **Input:** the issues to refine, by number, or none: then the open
  issues with the unready label.
- **Output:** each issue's title, body, type, labels and relationships
  updated after the user confirmed them, the unready label removed where
  nothing is left open, and a report.
- **Never:** write to GitHub before the user confirmed the restated plan;
  replace the author's feature with a different one; touch issues outside
  the named set, apart from the other end of a confirmed relationship;
  create issues.

## 0. Read the policy

If `.agents/policy/refine-draft-issues.md` exists, read it first. It holds
what this repository adds: the label for unready issues (`draft` by
default), the documents to read for each area, the constraints an issue
body should name when they bind it, the validation commands to propose,
and sections the body needs beyond those below.

## 1. Choose the issues

Use exactly the issues the user named. Otherwise list the candidates:

```sh
gh issue list --label draft --state open --limit 50
```

with the policy's label in place of `draft`. Say which you are about to
work on. With more than a handful and none named, ask which to take.

## 2. Read the thread, the relationships, then the code

For each issue, read the body and every comment
(`gh issue view <number> --comments`) and its relationships, the way the
`triage-issue` skill reads them. Later comments from the repository owner
supersede the body, and the comment that settles a question is often not
the newest. When the body and a comment disagree, the comment wins.

Compare the relationships with what the thread says: an ordering stated
only in prose is a missing blocked-by relationship, a split into parts is
missing sub-issues, and a relationship the thread has dropped is one to
remove.

Then read what the issue touches: `AGENTS.md`, the documents the policy
names for that area, and the source files the change would land in. An
issue that names no files should end up naming some.

## 3. Rewrite the body

- **Goal:** the outcome in the user's or maintainer's terms, one
  paragraph.
- **Scope:** what changes, naming concrete files or modules.
- **Constraints:** the rules that bind this work, only when they bind it,
  from `AGENTS.md` and the policy.
- **Acceptance criteria:** checkable statements, not aspirations.
- **Validation:** the exact commands.
- **Open questions:** only if any remain.

Keep the author's intent: sharpen vague wording, do not swap the feature.
A decision nobody has made, such as which of two behaviors is right or
what a number should be, goes under **Open questions** instead of being
picked. Prose may explain why one issue waits for another, but the
relationship is the record. Do not hard-wrap the body: GitHub renders the
line breaks.

## 4. Decide the metadata

Decide the type, labels, fields and relationships as the `triage-issue`
skill and its policy say. Reassess the type and labels: a refined scope
often changes them.

The issue leaves the unready label only when its scope, acceptance
criteria and validation are answerable from the issue alone. An issue with
entries under **Open questions** stays unready; then report the blocking
decision and who or what would settle it. That is a successful outcome.

## 5. Restate before writing

For each issue, show:

- its number, current title and proposed title;
- the type to set, the labels to add and remove, and any field change;
- the relationships to add and remove, by issue number, or that none
  change; a blocking or parent relationship is written on the other issue,
  so name it;
- whether it leaves the unready label;
- a short summary of how the body changes, and the full new body.

Wait for confirmation.

## 6. Write

Write each body to a file outside the repository, made with
`mktemp "${TMPDIR:-/tmp}/issue-body.XXXXXX"`, then:

```sh
gh issue edit <number> --title "..." --body-file <path>
```

Set the confirmed metadata with the `triage-issue` skill, giving it the
exact values, and remove the unready label where confirmed. It reads
everything back.

## 7. Report

One line per issue: its URL, whether it left the unready label, and what
changed. For an issue that stayed unready, the decision that blocks it.

## Stop conditions

- The core requirement is ambiguous → keep the issue unready and ask.
- The user has not confirmed the restated plan → write nothing.
- An issue is outside the named set → leave it alone, apart from the other
  end of a confirmed relationship.
- The work needs a new issue rather than an edit → propose it; do not
  create it here.
