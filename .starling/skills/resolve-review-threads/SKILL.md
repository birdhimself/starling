---
name: resolve-review-threads
description: Answers every unresolved review thread on a GitHub pull request. It judges each remark, has the changes worth making applied with apply-review-findings, replies in each thread with what changed or why not, and resolves the threads it answered. Ends at threads replied to and resolved. Use when asked to address review comments, apply review feedback, respond to reviewer remarks, handle bot review comments, or clear the unresolved threads on a pull request. Do not use for reviewing someone else's pull request, for findings that have no GitHub thread (use `apply-review-findings`), for marking a pull request ready (use `finish-pr`), or for creating or merging pull requests.
argument-hint: "[pr]"
---

# Resolve review threads

Every unresolved thread ends in one of two states: changed and answered, or
declined and answered. Silence is not an outcome. A reviewer, human or bot,
is a source of suggestions: judge each remark before touching the code.
Paths are relative to the repository root.

## Contract

- **Input:** a pull request number, or none: then the current branch's.
- **Output:** each thread replied to, and resolved unless it waits for an
  answer; the accepted changes folded and pushed; a report.
- **Never:** resolve a thread without replying in it; claim a change that
  was not made; fold work outside the pull request's topic into it; mark
  the pull request ready; merge.

## 0. Read the policy

If `.agents/policy/resolve-review-threads.md` exists, read it first. It
holds what this repository adds, such as the documents whose conventions
decide a remark.

## 1. Read every thread

```sh
.starling/skills/resolve-review-threads/scripts/threads <number>
gh pr view <number> --comments
```

`threads` prints each unresolved thread with its id, which resolving needs,
the id of its first comment, which a reply needs, its file and line, and
every comment. Top-level review bodies come from `gh pr view --comments`;
a reviewer often makes the substantive point there. Then read the code
around each remark: a remark that is wrong about what the code does is
common.

## 2. Judge each remark

- **Accept** a remark that names a real defect, a genuine simplification,
  or a rule this repository holds.
- **Decline** one whose premise is wrong, that would break a convention in
  an `AGENTS.md`, or whose cost outweighs its benefit. Weigh a remark by
  whether its condition can be reached: a rare race is worth a fix only
  when the fix is trivial. The same holds for speculative generality,
  checks for states the types already exclude, and style that contradicts
  the surrounding code.
- **Ask the user**, in one round, about a remark that needs a product
  decision, widens the scope past the pull request's topic, or contradicts
  something the user asked for.

Declining is answering, not skipping: a declined remark gets a reply with
the reason, and is resolved.

## 3. Apply the accepted remarks

Hand the accepted remarks to the `apply-review-findings` skill as findings
already sorted as apply: the file and line, the defect, and the change.
It fixes the cause, validates, folds each fix into the commit it corrects
and pushes. Note the commit each remark went into.

Work a remark reveals that does not belong here becomes a proposed
follow-up issue; when the user agrees, create it with the `triage-issue`
skill, blocked by the issue this pull request closes when it builds on
this change.

## 4. Reply in every thread

Reply to the thread's first comment:

```sh
gh api -X POST 'repos/{owner}/{repo}/pulls/<number>/comments/<comment-id>/replies' \
  -f body='<reply>'
```

In one or two sentences: for an accepted remark, what changed and where,
naming the commit; for a declined one, the concrete reason; for a deferred
one, the follow-up issue. If the change differs from what the remark
proposed, say so. Do not thank the reviewer, restate the remark, or claim a
fix you did not make.

## 5. Resolve the threads

Only GraphQL resolves a thread. After the reply has landed, one thread at a
time:

```sh
gh api graphql -F threadId='<thread-id>' -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: { threadId: $threadId }) { thread { isResolved } }
  }'
```

Resolve a thread you accepted and fixed, and one you declined and answered.
Leave it open when it asks the reviewer a question, or when the user has
not decided something it raised.

## 6. Report

The pull request's URL, then one line per thread: file and line, the
decision, and what came of it. Name the commits pushed, the validation run
and its results, proposed follow-up issues, and every thread left open with
the reason.

## Stop conditions

- A remark needs a product decision → ask; do not guess.
- A remark asks for work outside the pull request's topic → propose a
  follow-up issue; do not fold it in.
- A remark contradicts an `AGENTS.md` or the user → decline it in the
  thread.
- GraphQL is unavailable → reply through REST, and report the threads you
  could not resolve.
