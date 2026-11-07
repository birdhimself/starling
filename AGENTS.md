# Starling

Starling holds the agent instructions, skills, scripts and checks shared
across my repositories. It is installed into a repository as a `.starling/`
folder.

If a `.notes/` folder exists, read `.notes/design.md` (what was decided and
why) and `.notes/roadmap.md` (the steps, their status and the open questions)
before starting any task. When a step is finished, a decision changes or a
question is answered, update those files in the same change. They are private
and must never be copied into this repository.

- `.starling/` is the payload: exactly what a repository receives on install.
- Scripts use only POSIX `sh`, POSIX `awk` and git, and no temporary files.
- Run the tests with `sh tests/run`.
