---
name: triage-issue
description: Sets an issue's metadata by the repository's policy, including its type, labels and fields such as priority, its blocked-by and sub-issue relationships, and the draft label, and closes an issue as a duplicate or as not planned. Use when creating, classifying, relabeling, prioritizing, linking or closing an issue, or when another skill needs an issue's metadata set or read. Do not use for writing or rewriting an issue's body (use `refine-draft-issues`), for pull request labels, or for implementing an issue (use `implement-issue`).
argument-hint: "<issue> [what to set]"
---

# Triage an issue

Set an issue's type, labels, fields and relationships the way the
repository's policy asks, and close an issue that will not be worked on.
Relationships are the record of order and hierarchy between issues: prose
may explain them, but never replaces them.

## Contract

- **Input:** an issue number, or a new issue to create with its title and
  body; and what to set, or a request to classify it from its content. A
  caller such as `refine-draft-issues` may give the exact metadata: then
  start at "Set it".
- **Output:** the metadata set on the forge and read back, and a report.
- **Never:** change an issue's title or body, except the body of an issue
  it creates; set a field value nobody decided, such as a priority; invent
  a label, type or field the repository does not have; close an issue
  without the user asking for it.

## 0. Read the policy

If `.agents/policy/triage-issue.md` exists, read it first. It holds this
repository's rules: which issue types to use, which labels and how many of
each group, which fields exist with their ids and values, when to set them,
and the label that marks an unready issue. Follow it where it is more
specific than this skill.

Without a policy, set only what the request names, and only types and
labels that exist: `.starling/bin/forge label list` lists the labels.

`.starling/bin/forge` works on whichever forge the repository is on. Not
every forge has issue types, sub-issues or fields: where one is missing,
the command says so. Then use what the policy names in its place, such as
a label for the type or a task list in the parent for its parts. Without
such a rule, leave it unset and report it.

## 1. Read the issue

```sh
.starling/bin/forge issue view <number>
.starling/bin/forge issue relations <number>
```

`issue view` prints the title, state, type and labels, then the body and
every comment. `issue relations` prints the issues that block this one,
the ones it blocks, its parent and its sub-issues. Read the body and
comments when classifying: ordering stated only in prose ("lands after
#12", "depends on", "blocked by") is a missing blocked-by relationship, a
split into parts is missing sub-issues, and a relationship the thread has
since dropped is one to remove.

## 2. Decide

- **Type and labels:** from the policy and the issue's substance, not its
  title alone. Reassess all of them when the scope changed; a sharper scope
  often changes the type.
- **Fields:** only values that were decided, such as a priority someone
  stated in the thread. Never infer one to fill the field, and never clear
  a decided one.
- **Relationships:** an issue that lands after, depends on or is blocked by
  another is blocked by it. The parts of a split issue are its
  sub-issues. A follow-up issue is blocked by the issue it came from when
  it builds on that change; an independent one only mentions it.
- **Unready:** the policy's label for an issue that is not ready to
  implement stays until the issue is refined. Removing it is the
  `refine-draft-issues` skill's decision.

When you decided anything the request did not name, list what you will set,
one line each with its reason, before setting it.

## 3. Set it

Type and labels, each label option once per label:

```sh
.starling/bin/forge issue edit <number> --type "<type>" --add-label "<label>" --remove-label "<label>"
```

Creating an issue, with the body in a file:

```sh
.starling/bin/forge issue create --title "<plain sentence>" --body-file <path> --type "<type>" --label "<label>"
```

Relationships, by issue number:

```sh
.starling/bin/forge issue block <number> --by <other>
.starling/bin/forge issue sub <number> --of <parent>
```

Add `--remove` to take one away. A blocking or parent relationship is
written from the other issue: to make this issue block another, run
`issue block` for that one.

Fields exist only on GitHub and have no subcommand. Set one through the
API, with the field id from the policy:

```sh
echo '{"issue_field_values":[{"field_id":<id>,"value":"<value>"}]}' |
  .starling/bin/forge api -X POST 'repos/{owner}/{repo}/issues/<number>/issue-field-values' --input -
```

Closing, only when the user asked for it: a duplicate with
`.starling/bin/forge issue close <number> --duplicate-of <other>`, a
rejected issue with `.starling/bin/forge issue close <number> --not-planned`.
Do not label either.

## 4. Read it back

Run the commands of "Read the issue" again and compare: every type, label,
field and relationship you set is there, and nothing else changed.

## 5. Report

The issue's URL, and one line for each change: what was set or removed and
why. Name anything you left unset because nobody decided it.

## Stop conditions

- The policy names a type, label or field the repository does not have →
  report it, do not create it.
- A value needs a decision nobody made, such as a priority → leave it unset
  and say so.
- The forge cannot be reached or refuses for lack of permission → report
  the error; do not retry in a loop.
