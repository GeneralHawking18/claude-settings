#!/bin/bash
# install.sh — Cài đặt dotfiles cho Claude CLI (Linux / macOS / WSL)
# Copy file thẳng vào ~/.claude, ghi đè nếu đã tồn tại

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Dotfiles dir: $DOTFILES_DIR"
echo "Target dir:   $CLAUDE_DIR"
echo ""

# Tạo thư mục ~/.claude nếu chưa có
mkdir -p "$CLAUDE_DIR"

# Hàm copy có backup
copy_file() {
    local src="$1"
    local dst="$2"
    if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
        echo "  [bak] Backup: $dst -> ${dst}.bak"
    fi
    cp -f "$src" "$dst"
    echo "  [ok]  Copied: $dst"
}

echo "Copying Claude CLI settings..."
copy_file "$DOTFILES_DIR/claude/settings.json"         "$CLAUDE_DIR/settings.json"
copy_file "$DOTFILES_DIR/claude/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"

echo ""
echo "[DONE] Khoi dong lai Claude CLI de ap dung."
