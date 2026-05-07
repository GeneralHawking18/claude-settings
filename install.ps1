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

# Ham copy co backup (dung binary de giu nguyen encoding UTF-8)
# Backup va ghi file theo kieu stream de tranh loi file bi khoa boi tien trinh khac
function Copy-DotFile {
    param($src, $dst)

    # --- Backup (non-fatal: warn if file is locked) ---
    if (Test-Path $dst) {
        try {
            Copy-Item $dst "$dst.bak" -Force -ErrorAction Stop
            Write-Host "  [bak] Backup: $dst -> $dst.bak"
        } catch {
            Write-Warning "  [skip-bak] Cannot backup '$dst' (file locked by another process). Skipping backup."
        }
    }

    # --- Write source -> destination via raw streams ---
    try {
        $srcBytes = [System.IO.File]::ReadAllBytes($src)
        $fs = [System.IO.File]::Open($dst, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
        $fs.Write($srcBytes, 0, $srcBytes.Length)
        $fs.Close()
        Write-Host "  [ok]  Copied: $dst"
    } catch {
        Write-Error "  [ERR] Failed to write '$dst': $_"
        throw
    }
}

Write-Host "Copying Claude CLI settings..."
Copy-DotFile "$DOTFILES_DIR\claude\settings.json"            "$CLAUDE_DIR\settings.json"
Copy-DotFile "$DOTFILES_DIR\claude\statusline-command.sh"    "$CLAUDE_DIR\statusline-command.sh"
Copy-DotFile "$DOTFILES_DIR\claude\statusline-command.ps1"   "$CLAUDE_DIR\statusline-command.ps1"

Write-Host ""
Write-Host "[DONE] Khoi dong lai Claude CLI de ap dung."
