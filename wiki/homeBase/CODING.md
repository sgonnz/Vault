# Coding guidance

Applies when a session edits or tests code. Referenced from `AGENTS.md`.

- Bug fixes start by reproducing the bug end to end, as close to how a user hits it as practical. That way the fix targets the real cause, and the reproduction becomes the proof it works.
- When testing a product end to end, look at the UI with a critical eye. If something is clearly off, fix it along the way even when it is not the task at hand.
- Treat lint errors, failing tests, and flaky tests the same way: fix them when you meet them, even if they predate your change.
