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

The main session is the orchestrator: it plans, delegates to the role subagents defined in `wiki/agents/roles/`, verifies their work, and reports. The full procedure, role list, and escalation rules are in `wiki/agents/roles/orchestrator.md`; read it before delegating. Two rules apply before anything else:

- Delegate only when the work spans several files, needs a search of unknown scope, needs outside research, or would pull a lot of content into this context. Handle questions, one-file edits, quick fixes, and reads at known paths directly, and say so.
- Before spawning anything, show a short plan table (task, role, model, parallel or sequential) and wait for approval, unless the user already said to proceed without confirming.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
