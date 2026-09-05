# Points Claude Code and Codex at the vault's shared agent instructions and
# subagent definitions. Run once per machine after cloning the vault.
# Re-running is safe: every step is idempotent and backs up what it replaces.
$ErrorActionPreference = "Stop"
$vaultAgents = Join-Path $PSScriptRoot "wiki\homeBase\AGENTS.md"
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$codexDir = Join-Path $env:USERPROFILE ".codex"
New-Item -ItemType Directory -Force $claudeDir | Out-Null
New-Item -ItemType Directory -Force $codexDir | Out-Null

# ---------------------------------------------------------------------------
# 1. Global instructions (AGENTS.md)
# ---------------------------------------------------------------------------
# Claude Code follows @imports, so a one-line stub is enough.
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
if (Test-Path $claudeMd) { Copy-Item $claudeMd "$claudeMd.bak" -Force }
"# Global instructions`n`n@$vaultAgents" | Set-Content $claudeMd -Encoding utf8
"Claude: $claudeMd -> @$vaultAgents"

# Codex does not follow imports, so link its AGENTS.md to the vault file.
# Symlink needs admin or Developer Mode; fall back to a hard link (same drive only).
$codexMd = Join-Path $codexDir "AGENTS.md"
$codexMdItem = Get-Item $codexMd -ErrorAction SilentlyContinue
$alreadyLinked = $false
if ($codexMdItem -and $codexMdItem.LinkType) {
    $alreadyLinked = (Get-Content $codexMd -Raw) -eq (Get-Content $vaultAgents -Raw)
}
if (-not $alreadyLinked) {
    if ($codexMdItem) { Move-Item $codexMd "$codexMd.bak" -Force }
    try {
        New-Item -ItemType SymbolicLink -Path $codexMd -Target $vaultAgents -ErrorAction Stop | Out-Null
        "Codex: AGENTS.md symlink created"
    } catch {
        New-Item -ItemType HardLink -Path $codexMd -Target $vaultAgents -ErrorAction Stop | Out-Null
        "Codex: AGENTS.md hard link created (symlink needs admin or Developer Mode)"
    }
} else {
    "Codex: AGENTS.md already linked"
}

# ---------------------------------------------------------------------------
# 2. Subagent definitions (wiki/agents)
# ---------------------------------------------------------------------------
& (Join-Path $PSScriptRoot "wiki\agents\build-agents.ps1")

function Link-AgentsDir($linkPath, $sourceDir, $label) {
    # Prefer a directory junction (no admin needed). If the harness cannot read
    # through it, or creation fails, fall back to copying the files.
    $existing = Get-Item $linkPath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            # Delete the link itself, never its target.
            [System.IO.Directory]::Delete($linkPath)
        } else {
            $bak = "$linkPath.bak"
            if (Test-Path $bak) { Remove-Item $bak -Recurse -Force }
            Move-Item $linkPath $bak -Force
            "${label}: existing agents folder moved to $bak"
        }
    }
    try {
        New-Item -ItemType Junction -Path $linkPath -Target $sourceDir -ErrorAction Stop | Out-Null
        "${label}: $linkPath -> $sourceDir (junction)"
    } catch {
        New-Item -ItemType Directory -Force $linkPath | Out-Null
        Copy-Item (Join-Path $sourceDir "*") $linkPath -Force
        "${label}: junction failed, copied files into $linkPath (re-run after editing roles)"
    }
}

Link-AgentsDir (Join-Path $claudeDir "agents") (Join-Path $PSScriptRoot "wiki\agents\claude") "Claude"
Link-AgentsDir (Join-Path $codexDir "agents")  (Join-Path $PSScriptRoot "wiki\agents\codex")  "Codex"

# ---------------------------------------------------------------------------
# 3. Codex session model: Sol at high effort for the orchestrator (main session)
# ---------------------------------------------------------------------------
$codexConfig = Join-Path $codexDir "config.toml"
if (-not (Test-Path $codexConfig)) { "" | Set-Content $codexConfig -Encoding utf8 }
$cfg = Get-Content $codexConfig -Raw
$orig = $cfg

# Only touch the top-level (pre-table) lines, never a [profiles.*] or [agents] table.
$firstTable = $cfg.IndexOf("`n[")
if ($firstTable -lt 0) { $firstTable = $cfg.Length }
$top = $cfg.Substring(0, $firstTable)
$rest = $cfg.Substring($firstTable)
if ($top -match '(?m)^model\s*=') {
    $top = $top -replace '(?m)^model\s*=.*$', 'model = "gpt-5.6-sol"'
} else {
    $top = "model = `"gpt-5.6-sol`"`n" + $top
}
if ($top -match '(?m)^model_reasoning_effort\s*=') {
    $top = $top -replace '(?m)^model_reasoning_effort\s*=.*$', 'model_reasoning_effort = "high"'
} else {
    $top = $top -replace '(?m)^(model = "gpt-5.6-sol")$', "`$1`nmodel_reasoning_effort = `"high`""
}
$cfg = $top + $rest

if ($cfg -notmatch '(?m)^\[agents\]') {
    $cfg = $cfg.TrimEnd() + @"


[agents]
max_concurrent_threads_per_session = 4
default_subagent_model = "gpt-5.6-terra"
default_subagent_reasoning_effort = "medium"
"@ + "`n"
}

if ($cfg -ne $orig) {
    Copy-Item $codexConfig "$codexConfig.bak" -Force
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($codexConfig, $cfg, $enc)
    "Codex: config.toml updated (backup at $codexConfig.bak)"
} else {
    "Codex: config.toml already up to date"
}

# ---------------------------------------------------------------------------
# 4. Claude Code launcher: whole session runs as the orchestrator agent (Opus)
# ---------------------------------------------------------------------------
$launcher = Join-Path $PSScriptRoot "orchestrate.cmd"
"@echo off`r`nclaude --agent orchestrator %*`r`n" | Set-Content $launcher -Encoding ascii -NoNewline
"Claude: launcher written to $launcher (run it from the vault to start the orchestrator)"
