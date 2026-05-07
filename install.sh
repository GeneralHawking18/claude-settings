#!/bin/bash
# install.sh — Cài đặt dotfiles cho Claude CLI
# Dùng symlink nên mọi thay đổi trong repo sẽ tự áp dụng ngay

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "📁 Dotfiles dir: $DOTFILES_DIR"
echo "🎯 Target dir:   $CLAUDE_DIR"
echo ""

# Tạo thư mục ~/.claude nếu chưa có
mkdir -p "$CLAUDE_DIR"

# Hàm symlink có backup
link() {
    local src="$1"
    local dst="$2"
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        echo "  📦 Backup: $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    echo "  ✓ Linked: $dst"
}

echo "🔗 Linking Claude CLI settings..."
link "$DOTFILES_DIR/claude/settings.json"          "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/claude/statusline-command.sh"  "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"

echo ""
echo "✅ Done! Khởi động lại Claude CLI để áp dụng."
