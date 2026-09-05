# Renders wiki/agents/roles/*.md into
#   wiki/agents/claude/<name>.md   (Claude Code subagent format)
#   wiki/agents/codex/<name>.toml  (Codex custom agent format)
# Each role file is a markdown document with a simple key: value frontmatter.
# The global rules from wiki/homeBase/AGENTS.md (everything before the first
# "## " heading) are prepended to every agent body, because neither harness
# passes CLAUDE.md / AGENTS.md down to subagents.
# Idempotent; safe to re-run. Requires only Windows PowerShell 5.1.

$ErrorActionPreference = "Stop"
$root      = $PSScriptRoot
$rolesDir  = Join-Path $root "roles"
$claudeDir = Join-Path $root "claude"
$codexDir  = Join-Path $root "codex"
$agentsMd  = Join-Path $root "..\homeBase\AGENTS.md"

New-Item -ItemType Directory -Force $claudeDir | Out-Null
New-Item -ItemType Directory -Force $codexDir  | Out-Null

function Read-Utf8($path) {
    [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}
function Write-Utf8($path, $text) {
    # LF line endings, UTF-8 without BOM, to match the rest of the vault.
    $text = $text -replace "`r`n", "`n"
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $text, $enc)
}

function Parse-Role($path) {
    $text = (Read-Utf8 $path) -replace "`r`n", "`n"
    if ($text -notmatch '(?s)^---\n(.*?)\n---\n(.*)$') {
        throw "Role file has no frontmatter: $path"
    }
    $frontmatter = $Matches[1]
    $bodyText    = $Matches[2].Trim()
    $meta = @{}
    foreach ($line in ($frontmatter -split "`n")) {
        if ($line -match '^\s*([A-Za-z_]+)\s*:\s*(.*)$') {
            $meta[$Matches[1]] = $Matches[2].Trim()
        }
    }
    foreach ($required in @("name", "description")) {
        if (-not $meta.ContainsKey($required)) { throw "Role $path is missing '$required'" }
    }
    return @{ meta = $meta; body = $bodyText }
}

# Global rules: the top section of AGENTS.md, bullets only, heading dropped.
$agentsText = (Read-Utf8 $agentsMd) -replace "`r`n", "`n"
$globalRules = ($agentsText -split "`n## ")[0]
$globalRules = ($globalRules -replace '^# [^\n]*\n', '').Trim()

$roles = Get-ChildItem $rolesDir -Filter *.md | Sort-Object Name
$claudeOut = @()
$codexOut  = @()

foreach ($file in $roles) {
    $role = Parse-Role $file.FullName
    $m = $role.meta
    $name = $m.name
    $body = "Global rules (apply to every agent):`n`n$globalRules`n`n$($role.body)`n"

    # ---- Claude Code ----
    if ($m.ContainsKey("claude_model")) {
        $fm = @("---", "name: $name", "description: $($m.description)", "model: $($m.claude_model)")
        if ($m.ContainsKey("claude_tools"))            { $fm += "tools: $($m.claude_tools)" }
        if ($m.ContainsKey("claude_disallowed_tools")) { $fm += "disallowedTools: $($m.claude_disallowed_tools)" }
        if ($m.ContainsKey("claude_permission"))       { $fm += "permissionMode: $($m.claude_permission)" }
        if ($m.ContainsKey("claude_memory"))           { $fm += "memory: $($m.claude_memory)" }
        $fm += "---"
        Write-Utf8 (Join-Path $claudeDir "$name.md") (($fm -join "`n") + "`n" + $body)
        $claudeOut += $name
    }

    # ---- Codex ----
    $forCodex = -not ($m.ContainsKey("codex") -and $m.codex -eq "false")
    if ($forCodex -and $m.ContainsKey("codex_model")) {
        if ($body -match "'''") { throw "Role $name body contains ''' which cannot be embedded in a TOML literal string" }
        $desc = $m.description -replace '\\', '\\' -replace '"', '\"'
        $lines = @(
            "name = `"$name`"",
            "description = `"$desc`"",
            "model = `"$($m.codex_model)`""
        )
        if ($m.ContainsKey("codex_effort"))  { $lines += "model_reasoning_effort = `"$($m.codex_effort)`"" }
        if ($m.ContainsKey("codex_sandbox")) { $lines += "sandbox_mode = `"$($m.codex_sandbox)`"" }
        $lines += ""
        $lines += "developer_instructions = '''"
        $lines += $body.TrimEnd()
        $lines += "'''"
        Write-Utf8 (Join-Path $codexDir "$name.toml") (($lines -join "`n") + "`n")
        $codexOut += $name
    }
}

# Remove generated files whose role no longer exists.
foreach ($f in Get-ChildItem $claudeDir -Filter *.md) {
    if ($claudeOut -notcontains $f.BaseName) { Remove-Item $f.FullName; "removed stale $($f.Name)" }
}
foreach ($f in Get-ChildItem $codexDir -Filter *.toml) {
    if ($codexOut -notcontains $f.BaseName) { Remove-Item $f.FullName; "removed stale $($f.Name)" }
}

"Claude agents ($($claudeOut.Count)): $($claudeOut -join ', ')"
"Codex agents  ($($codexOut.Count)): $($codexOut -join ', ')"
