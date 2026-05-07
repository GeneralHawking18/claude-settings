# install.ps1 - Cai dat dotfiles cho Claude CLI (Windows)
# Copy file thang vao %USERPROFILE%\.claude, ghi de neu da ton tai

$ErrorActionPreference = "Stop"

$DOTFILES_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CLAUDE_DIR   = "$env:USERPROFILE\.claude"

Write-Host "Dotfiles dir: $DOTFILES_DIR"
Write-Host "Target dir:   $CLAUDE_DIR"
Write-Host ""

# Tao thu muc .claude neu chua co
if (-not (Test-Path $CLAUDE_DIR)) {
    New-Item -ItemType Directory -Path $CLAUDE_DIR | Out-Null
    Write-Host "  [+] Created: $CLAUDE_DIR"
}

# Ham copy co backup (dung binary Copy-Item de giu nguyen encoding UTF-8)
function Copy-DotFile {
    param($src, $dst)
    if (Test-Path $dst) {
        Copy-Item $dst "$dst.bak" -Force
        Write-Host "  [bak] Backup: $dst -> $dst.bak"
    }
    Copy-Item $src $dst -Force
    Write-Host "  [ok]  Copied: $dst"
}

Write-Host "Copying Claude CLI settings..."
Copy-DotFile "$DOTFILES_DIR\claude\settings.json"         "$CLAUDE_DIR\settings.json"
Copy-DotFile "$DOTFILES_DIR\claude\statusline-command.sh" "$CLAUDE_DIR\statusline-command.sh"

Write-Host ""
Write-Host "[DONE] Khoi dong lai Claude CLI de ap dung."
