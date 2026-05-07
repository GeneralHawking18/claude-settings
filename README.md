# dotfiles

Cấu hình cá nhân cho **Claude CLI** (`claude` command), sync qua nhiều máy bằng Git + symlink.

## Nội dung

| File | Mô tả |
|------|-------|
| `claude/settings.json` | Cấu hình Claude CLI (statusline, plugins, permissions) |
| `claude/statusline-command.sh` | Script thanh trạng thái dưới terminal |

### Statusline hiển thị

```
◆ Snt4.6 │ $ 0.12 │ ↕ 45k/8k │ ▣ [██░░]48% │ ↺ 72% │ ◉ [█░░░]23% 3h12m │ ▶ 4s
```

| Ký hiệu | Ý nghĩa |
|---------|---------|
| `◆ Snt4.6` | Model đang dùng (rút gọn) |
| `$ 0.12` | Chi phí session ($USD) |
| `↕ 45k/8k` | Tokens in/out |
| `▣ [██░░]48%` | % context window đã dùng |
| `↺ 72%` | Hiệu suất cache prompt |
| `◉ [█░░░]23% 3h12m` | Rate limit 5h + thời gian reset |
| `▶ 4s` | Thời gian turn |

---

## Cài đặt trên máy mới

### Yêu cầu

- `git`
- `jq` — parse JSON trong statusline
- `bc` — tính toán số thực
- Claude CLI đã được cài (`npm install -g @anthropic-ai/claude-code`)

```bash
# Ubuntu/Debian
sudo apt install -y jq bc

# macOS
brew install jq bc
```

### Bước 1 — Clone repo

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
```

### Bước 2 — Chạy install script

```bash
bash ~/dotfiles/install.sh
```

Script sẽ:
- Tạo symlink `~/.claude/settings.json` → repo
- Tạo symlink `~/.claude/statusline-command.sh` → repo
- Backup file cũ nếu có (thêm đuôi `.bak`)

### Bước 3 — Đăng nhập Claude CLI

```bash
claude login
```

Sau đó khởi động lại terminal hoặc chạy `claude` để kiểm tra statusline.

---

## Cập nhật settings

Vì dùng symlink, chỉ cần:

```bash
cd ~/dotfiles
# sửa file trong claude/
git add . && git commit -m "update: ..."
git push
```

Trên các máy khác:

```bash
cd ~/dotfiles && git pull
# Không cần chạy install lại — symlink tự áp dụng
```

---

## Plugins đang dùng

Sau khi cài, bật plugins trong Claude CLI:

```bash
claude plugins install ralph-loop@claude-plugins-official
claude plugins install claude-mem@thedotmack
claude plugins install context7@claude-plugins-official
```

> **Lưu ý:** Plugins được lưu trong `settings.json` nhưng cần cài riêng trên từng máy.

---

## Cấu trúc repo

```
dotfiles/
├── install.sh                    # Script cài đặt symlink
├── README.md
└── claude/
    ├── settings.json             # Claude CLI config
    └── statusline-command.sh     # Statusline script
```
