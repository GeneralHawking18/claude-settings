#!/usr/bin/env pwsh
# statusline-command.ps1 - Windows native statusline cho Claude CLI
# Claude CLI pipe JSON vao stdin, script doc va format thanh status bar

# Bat UTF-8 de hien thi dung Unicode symbols
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$input_raw = $null
try { $input_raw = [Console]::In.ReadToEnd() } catch {}

if (-not $input_raw -or $input_raw.Trim() -eq '') {
    Write-Host -NoNewline 'Claude'
    exit 0
}

try {
    $data = $input_raw | ConvertFrom-Json
} catch {
    Write-Host -NoNewline 'Claude'
    exit 0
}

$cost      = $data.cost.total_cost_usd
$used_pct  = $data.context_window.used_percentage
$total_in  = $data.context_window.total_input_tokens
$total_out = $data.context_window.total_output_tokens
$model_id  = if ($data.model.id) { $data.model.id } else { $data.model.display_name }
$dur_ms    = $data.cost.total_duration_ms
$cache_r   = $data.context_window.current_usage.cache_read_input_tokens
$input_tok = $data.context_window.current_usage.input_tokens
$rl_pct    = $data.rate_limits.five_hour.used_percentage
$rl_reset  = $data.rate_limits.five_hour.resets_at

function Shorten-Model($id) {
    if (-not $id) { return '' }
    $ver = [regex]::Match($id, '\d+(-\d+)+').Value -replace '-','.' -replace '(\d+\.\d+).*','$1'
    switch -Wildcard ($id) {
        '*sonnet*' { return "Snt$ver" }
        '*opus*'   { return "Ops$ver" }
        '*haiku*'  { return "Hku$ver" }
        default    { return $id -replace '^claude-','' -replace '-\d{8}$','' }
    }
}

function Make-Bar($pct, $size=4) {
    $filled = [math]::Round($pct * $size / 100)
    $bar = ''
    for ($i = 1; $i -le $size; $i++) {
        $bar += if ($i -le $filled) { [char]0x2588 } else { [char]0x2591 }
    }
    return $bar
}

function Fmt-Duration($ms) {
    if (-not $ms -or $ms -eq 0) { return '' }
    $s = [int]($ms / 1000); $m = [int]($ms / 60000); $h = [int]($ms / 3600000)
    if ($h -gt 0)    { return "${h}h$([int](($ms/60000) % 60))m" }
    elseif ($m -gt 0){ return "${m}m$([int]($s % 60))s" }
    else              { return "${s}s" }
}

$sep   = ' | '
$parts = @()

# Model
$ms = Shorten-Model $model_id
if ($ms) { $parts += ([char]0x25C6) + " $ms" }

if ($null -ne $used_pct) {
    # Cost
    if ($null -ne $cost) {
        $parts += '$ ' + ([math]::Round($cost, 2).ToString('F2'))
    }

    # Tokens in/out
    if ($null -ne $total_in) {
        $ink  = [math]::Round($total_in / 1000)
        $_out = if ($total_out) { $total_out } else { 0 }
        $outk = [math]::Round($_out / 1000)
        $tok_str = if ($outk -gt 0) { "${ink}k/${outk}k" } else { "${ink}k" }
        $parts += ([char]0x2195) + " $tok_str"
    }

    # Context bar
    $bar     = Make-Bar $used_pct
    $pct_fmt = [math]::Round($used_pct)
    $parts  += ([char]0x25A3) + " [$bar]${pct_fmt}%"

    # Cache efficiency
    if ($cache_r -gt 0) {
        $tot = $cache_r + $input_tok
        if ($tot -gt 0) {
            $cpct = [math]::Round($cache_r * 100 / $tot)
            $parts += ([char]0x21BA) + " ${cpct}%"
        }
    }

    # Rate limit
    if ($null -ne $rl_pct -and $null -ne $rl_reset) {
        $rl_bar   = Make-Bar $rl_pct
        $rl_fmt   = [math]::Round($rl_pct)
        $now      = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $resets_in = $rl_reset - $now
        $reset_str = if ($resets_in -gt 0) {
            $rm = [int]($resets_in / 60)
            "$([int]($rm/60))h$([int]($rm%60))m"
        } else { 'soon' }
        $parts += ([char]0x25C9) + " [$rl_bar]${rl_fmt}% $reset_str"
    }

    # Duration
    $dur = Fmt-Duration $dur_ms
    if ($dur) { $parts += ([char]0x25B6) + " $dur" }
}

Write-Host -NoNewline ($parts -join $sep)
