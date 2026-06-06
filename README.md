# claude-settings

Cấu hình cá nhân cho **Claude CLI** (`claude` command), đóng gói thành npm package — cài được trên mọi OS chỉ với một lệnh duy nhất.

## Cài đặt trên máy mới

```bash
npx @chunghoanganh/claude-settings install
```

Hoặc không qua npm (clone repo trước):

```bash
node bin/claude-settings.js install
```

Lệnh này sẽ:
- Copy `statusline.js` → `~/.claude/statusline.js` (backup `.bak` nếu đã tồn tại)
- Merge preset settings vào `~/.claude/settings.json` (giữ nguyên key khác của bạn)
- Set `statusLine.command` với absolute path đến `~/.claude/statusline.js`

### Xem trước thay đổi (không ghi file)

```bash
npx @chunghoanganh/claude-settings install --dry-run
```

## Statusline hiển thị

```
◆ Snt4.6 │ $ 0.12 │ ↕ 45k/8k │ ▣ [██░░]48% │ ↺ 72% │ ◉ [█░░░]23% 3h12m │ ◎ [█░░░]18% 5d3h │ ▶ 4s
```

| Ký hiệu | Ý nghĩa |
|---------|---------|
| `◆ Snt4.6` | Model đang dùng (rút gọn) |
| `$ 0.12` | Chi phí session ($USD) |
| `↕ 45k/8k` | Tokens in/out |
| `▣ [██░░]48%` | % context window đã dùng |
| `↺ 72%` | Hiệu suất cache prompt |
| `◉ [█░░░]23% 3h12m` | Rate limit 5h + thời gian reset |
| `◎ [█░░░]18% 5d3h` | Rate limit 7 ngày + thời gian reset |
| `▶ 4s` | Thời gian turn |

## Cập nhật settings

```bash
cd ~/path/to/claude-settings && git pull
node bin/claude-settings.js install
```

## Publish lên npm (personal)

```bash
npm login
npm publish --access public
```

## Cấu trúc repo

```
claude-settings/
├── bin/
│   └── claude-settings.js    # CLI installer (install / --dry-run)
├── src/
│   ├── statusline.js          # Statusline script (Node, cross-platform)
│   ├── install.js             # Logic: deep-merge, copy, backup
│   └── defaults.json          # Preset settings
├── package.json
└── README.md
```

## Yêu cầu

- Node.js ≥ 18 (đã có sẵn nếu dùng Claude CLI)
