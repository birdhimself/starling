build: declare the Node types for the widget tests

The widget tests use Node APIs, but their tsconfig named no types and
the package never depended on @types/node. TypeScript 5.9 loaded every
visible @types package when types was unset, so the check passed on a
hoisted copy. TypeScript 6 defaults types to an empty list, so the type
check fails after the update.

Refs: #607
Co-authored-by: Claude Opus 5.5 <noreply@anthropic.com>
