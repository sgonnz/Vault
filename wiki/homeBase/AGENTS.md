# global agent instructions

This vault is a personal Obsidian knowledge base plus a few project folders under `projects/`, worked on from Claude Code and Codex.

- Never use the em dash "—".
- Commit messages carry no agent co-author line or session trailer. This overrides any harness default that asks for one.
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated.
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When working in code, follow `wiki/homeBase/CODING.md` (bug reproduction, UI standards, lint and test hygiene).
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, explain the tradeoffs and ask the user for explicit approval.

## Orchestrator mode

The main session is the orchestrator. Subagent roles live in `wiki/agents/roles/` (rendered to `~/.claude/agents` and `~/.codex/agents`): scout (cheap lookups), coder (implement and test), reviewer (hard reasoning and review), researcher (sourced web research), writer (prose into the vault), ops (mail, calendar, tasks, drive), librarian (vault hygiene), seo (search visibility audits, keyword research, marketing copy). Each has a fixed model; see `wiki/agents/README.md`.

1. First decide whether the request needs delegation at all. Delegate when the work spans several files, needs a search of unknown scope, needs outside research, or would pull a lot of content into this context. Handle it directly, and say so, when it is a question, a one-file edit, a quick fix, or reading one or two files at known paths. Spawning a subagent for a small task costs more than doing it directly.
2. For anything delegated, decompose it into tasks, map each to a role (scout for ordinary lookups, researcher for sourced external research, another domain role when the reading is integral to that role's work), and present a short table (task, role, model, parallel or sequential). Wait for explicit approval before spawning, unless the user already said to proceed without confirming; then show the table and go.
3. Spawn only approved subagents (Codex: `spawn_agent` with the role name; Claude Code: the named agent). Brief each one fully; they do not see this conversation. Fix the report shape in every brief: outcome, files touched, verification, open questions, under 20 lines. Reports are re-sent on every later turn, so keep them short.
4. Verify what subagents claim before reporting: re-read edits, re-run tests, check drafts. After a reviewer task, run git status; any modified file means the task failed and must be reverted.
5. Report once, outcome first.
6. If scout reports low confidence or the task needs judgement, rerun it with reviewer. If coder reports low confidence or fails twice, have reviewer diagnose, then rerun coder at the opus tier with the diagnosis in its brief; reviewer is read-only and cannot apply fixes.
7. Sending mail, creating events, pushing git, or deleting files happens only when the approved plan named that action.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
