# Agent system

One orchestrator you talk to, plus a fixed set of subagent roles with a fixed model each. Works in both Claude Code and Codex from the same role definitions.

## How it fits together

- `roles/*.md` is the single source of truth. Each file has a small frontmatter (name, description, model per harness, tool limits) and the role's instructions as the body.
- `build-agents.ps1` renders every role into `claude/<name>.md` (Claude Code subagent) and `codex/<name>.toml` (Codex custom agent). Both output folders are committed so a fresh clone works without running anything.
- `setup-agent-config.ps1` in the vault root runs the build, then points `~/.claude/agents` and `~/.codex/agents` at the generated folders (directory junctions, with a copy fallback).
- The orchestrator is the main session, not a subagent. In Claude Code it is the `orchestrator` agent run session-wide via `orchestrate.cmd` in the vault root (Opus, medium effort). In Codex the main session already runs Sol at high effort and follows the Orchestrator mode section in `wiki/homeBase/AGENTS.md`.
- Subagents do not inherit CLAUDE.md or AGENTS.md, so the build prepends the global rules (the bullets above the first `##` heading in AGENTS.md) into every generated agent.

## Roles

| Role | Claude | Codex | Access |
|---|---|---|---|
| scout | haiku | luna, low | read-only |
| coder | sonnet | terra, medium | edit and shell |
| reviewer | opus | sol, high | read-only, may run tests |
| researcher | sonnet | terra, high | read-only plus web |
| writer | sonnet | terra, medium | writes in the vault |
| ops | sonnet | terra, medium | connected services only, drafts before sends |
| librarian | haiku | luna, medium | writes in the vault, git mv |
| seo | sonnet | terra, medium | web research, edits site pages and metadata |
| orchestrator | opus | (AGENTS.md) | everything |

## Adding or changing a role

1. Edit or add a file in `roles/`. Frontmatter keys: `name`, `description`, `claude_model` (haiku, sonnet, opus), optional `claude_tools`, `claude_disallowed_tools`, `claude_permission`, `claude_memory`; `codex_model` (gpt-5.6-luna, gpt-5.6-terra, gpt-5.6-sol), `codex_effort` (low, medium, high), `codex_sandbox` (read-only, workspace-write); `codex: false` to skip the Codex output.
2. Run `.\wiki\agents\build-agents.ps1` from the vault root.
3. If you added a role, mention it in the orchestrator role body and in the Orchestrator mode section of AGENTS.md so both harnesses know to use it.
4. Commit `roles/`, `claude/`, and `codex/` together.

Claude Code picks up changes on the next session start. Codex reads `~/.codex/agents` on start as well.
