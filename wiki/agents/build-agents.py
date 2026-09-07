#!/usr/bin/env python3
# Renders wiki/agents/roles/*.md into
#   wiki/agents/claude/<name>.md   (Claude Code subagent format)
#   wiki/agents/codex/<name>.toml  (Codex custom agent format)
# Each role file is a markdown document with a simple key: value frontmatter.
# The global rules from wiki/homeBase/AGENTS.md (everything before the first
# "## " heading) are prepended to every agent body, because neither harness
# passes CLAUDE.md / AGENTS.md down to subagents.
# Idempotent; safe to re-run. Port of build-agents.ps1; requires Python 3.8+.
import os
import re

root      = os.path.dirname(os.path.abspath(__file__))
rolesDir  = os.path.join(root, "roles")
claudeDir = os.path.join(root, "claude")
codexDir  = os.path.join(root, "codex")
agentsMd  = os.path.join(root, "..", "homeBase", "AGENTS.md")

os.makedirs(claudeDir, exist_ok=True)
os.makedirs(codexDir, exist_ok=True)


def read_utf8(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def write_utf8(path, text):
    # LF line endings, UTF-8 without BOM, to match the rest of the vault.
    text = text.replace("\r\n", "\n")
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


def parse_role(path):
    text = read_utf8(path).replace("\r\n", "\n")
    m = re.match(r"(?s)^---\n(.*?)\n---\n(.*)$", text)
    if not m:
        raise RuntimeError(f"Role file has no frontmatter: {path}")
    frontmatter, body = m.group(1), m.group(2).strip()
    meta = {}
    for line in frontmatter.split("\n"):
        mm = re.match(r"^\s*([A-Za-z_]+)\s*:\s*(.*)$", line)
        if mm:
            meta[mm.group(1)] = mm.group(2).strip()
    for required in ("name", "description"):
        if required not in meta:
            raise RuntimeError(f"Role {path} is missing '{required}'")
    return meta, body


# Global rules: the top section of AGENTS.md, bullets only, heading dropped.
agentsText = read_utf8(agentsMd).replace("\r\n", "\n")
globalRules = agentsText.split("\n## ")[0]
globalRules = re.sub(r"^# [^\n]*\n", "", globalRules).strip()

roles = sorted(f for f in os.listdir(rolesDir) if f.endswith(".md"))
claudeOut, codexOut = [], []

for fname in roles:
    meta, roleBody = parse_role(os.path.join(rolesDir, fname))
    name = meta["name"]
    body = f"Global rules (apply to every agent):\n\n{globalRules}\n\n{roleBody}\n"

    # ---- Claude Code ----
    if "claude_model" in meta:
        fm = ["---", f"name: {name}", f"description: {meta['description']}",
              f"model: {meta['claude_model']}"]
        if "claude_tools" in meta:
            fm.append(f"tools: {meta['claude_tools']}")
        if "claude_disallowed_tools" in meta:
            fm.append(f"disallowedTools: {meta['claude_disallowed_tools']}")
        if "claude_permission" in meta:
            fm.append(f"permissionMode: {meta['claude_permission']}")
        if "claude_memory" in meta:
            fm.append(f"memory: {meta['claude_memory']}")
        fm.append("---")
        write_utf8(os.path.join(claudeDir, f"{name}.md"), "\n".join(fm) + "\n" + body)
        claudeOut.append(name)

    # ---- Codex ----
    forCodex = meta.get("codex") != "false"
    if forCodex and "codex_model" in meta:
        if "'''" in body:
            raise RuntimeError(f"Role {name} body contains ''' which cannot be embedded in a TOML literal string")
        desc = meta["description"].replace("\\", "\\").replace('"', '\\"')
        lines = [f'name = "{name}"', f'description = "{desc}"', f'model = "{meta["codex_model"]}"']
        if "codex_effort" in meta:
            lines.append(f'model_reasoning_effort = "{meta["codex_effort"]}"')
        if "codex_sandbox" in meta:
            lines.append(f'sandbox_mode = "{meta["codex_sandbox"]}"')
        lines.append("")
        lines.append("developer_instructions = '''")
        lines.append(body.rstrip())
        lines.append("'''")
        write_utf8(os.path.join(codexDir, f"{name}.toml"), "\n".join(lines) + "\n")
        codexOut.append(name)

# Remove generated files whose role no longer exists.
for f in os.listdir(claudeDir):
    if f.endswith(".md") and f[:-len(".md")] not in claudeOut:
        os.remove(os.path.join(claudeDir, f))
        print(f"removed stale {f}")
for f in os.listdir(codexDir):
    if f.endswith(".toml") and f[:-len(".toml")] not in codexOut:
        os.remove(os.path.join(codexDir, f))
        print(f"removed stale {f}")

print(f"Claude agents ({len(claudeOut)}): {', '.join(claudeOut)}")
print(f"Codex agents  ({len(codexOut)}): {', '.join(codexOut)}")
