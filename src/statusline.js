#!/usr/bin/env node
let raw = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", c => (raw += c));
process.stdin.on("end", () => {
    let d = {};
    try { d = JSON.parse(raw); } catch { /* fallback to empty */ }
    process.stdout.write(render(d));
});

function get(d, ...path) {
    return path.reduce((o, k) => (o != null && typeof o === "object" ? o[k] : undefined), d);
}

function shorten(id) {
    if (!id) return "";
    const m = id.match(/(\d+)-(\d+)/);
    const ver = m ? `${m[1]}.${m[2]}` : "";
    if (id.includes("sonnet")) return `Snt${ver}`;
    if (id.includes("opus"))   return `Ops${ver}`;
    if (id.includes("haiku"))  return `Hku${ver}`;
    return id.replace(/^claude-/, "").replace(/-\d{8}$/, "");
}

function bar(pct, size = 4) {
    const filled = Math.min(size, Math.max(0, Math.round((pct * size) / 100)));
    return "█".repeat(filled) + "░".repeat(size - filled);
}

function fmtDur(ms) {
    if (!ms) return "";
    ms = Math.floor(ms);
    if (ms === 0) return "";
    const s = Math.floor(ms / 1000);
    const m = Math.floor(ms / 60000);
    const h = Math.floor(ms / 3600000);
    if (h > 0) return `${h}h${Math.floor((ms / 60000) % 60)}m`;
    if (m > 0) return `${m}m${s % 60}s`;
    return `${s}s`;
}

function render(d) {
    const model   = get(d, "model", "id") ?? get(d, "model", "display_name");
    const usedPct = get(d, "context_window", "used_percentage");
    const sep     = " │ ";

    if (usedPct == null) {
        return model ? `◆ ${shorten(model)}` : "Claude";
    }

    const parts = [];

    const modelS = shorten(model);
    if (modelS) parts.push(`◆ ${modelS}`);

    const cost = get(d, "cost", "total_cost_usd");
    if (cost != null) parts.push(`$ ${Number(cost).toFixed(2)}`);

    const totalIn  = get(d, "context_window", "total_input_tokens");
    const totalOut = get(d, "context_window", "total_output_tokens") ?? 0;
    if (totalIn != null) {
        parts.push(`↕ ${Math.floor(totalIn / 1000)}k/${Math.floor(totalOut / 1000)}k`);
    }

    parts.push(`▣ [${bar(usedPct)}]${Math.round(usedPct)}%`);

    const cacheRead  = get(d, "context_window", "current_usage", "cache_read_input_tokens") ?? 0;
    const inputToks  = get(d, "context_window", "current_usage", "input_tokens") ?? 0;
    if (cacheRead > 0) {
        const total = cacheRead + inputToks;
        if (total > 0) parts.push(`↺ ${Math.floor((cacheRead * 100) / total)}%`);
    }

    const rl5hPct    = get(d, "rate_limits", "five_hour", "used_percentage");
    const rl5hResets = get(d, "rate_limits", "five_hour", "resets_at");
    if (rl5hPct != null && rl5hResets != null) {
        const resetsIn = Math.floor(rl5hResets) - Math.floor(Date.now() / 1000);
        let resetStr;
        if (resetsIn > 0) {
            const rm = Math.floor(resetsIn / 60);
            resetStr = `${Math.floor(rm / 60)}h${rm % 60}m`;
        } else {
            resetStr = "soon";
        }
        parts.push(`◉ [${bar(rl5hPct)}]${Math.round(rl5hPct)}% ${resetStr}`);
    }

    const rl7dPct    = get(d, "rate_limits", "seven_day", "used_percentage");
    const rl7dResets = get(d, "rate_limits", "seven_day", "resets_at");
    if (rl7dPct != null && rl7dResets != null) {
        const resetsIn = Math.floor(rl7dResets) - Math.floor(Date.now() / 1000);
        let resetStr;
        if (resetsIn > 0) {
            const days = Math.floor(resetsIn / 86400);
            const hrs  = Math.floor((resetsIn % 86400) / 3600);
            const mins = Math.floor((resetsIn % 3600) / 60);
            resetStr = days > 0 ? `${days}d${hrs}h` : `${hrs}h${mins}m`;
        } else {
            resetStr = "soon";
        }
        parts.push(`◎ [${bar(rl7dPct)}]${Math.round(rl7dPct)}% ${resetStr}`);
    }

    const dur = fmtDur(get(d, "cost", "total_duration_ms"));
    if (dur) parts.push(`▶ ${dur}`);

    return parts.join(sep);
}
