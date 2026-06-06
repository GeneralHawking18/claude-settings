import { promises as fs } from "node:fs";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export async function install({ dryRun = false } = {}) {
    const claudeDir     = path.join(os.homedir(), ".claude");
    const statuslineDst = path.join(claudeDir, "statusline.js");
    const settingsPath  = path.join(claudeDir, "settings.json");
    const statuslineSrc = path.join(__dirname, "statusline.js");
    const defaultsPath  = path.join(__dirname, "defaults.json");

    if (!dryRun) await fs.mkdir(claudeDir, { recursive: true });

    const statuslineChanged = await copyWithBackup(statuslineSrc, statuslineDst, dryRun);

    const defaults = JSON.parse(await fs.readFile(defaultsPath, "utf8"));
    defaults.statusLine = { type: "command", command: `node ${statuslineDst}` };

    let current = {};
    try { current = JSON.parse(await fs.readFile(settingsPath, "utf8")); }
    catch (e) { if (e.code !== "ENOENT") throw e; }

    const merged  = deepMerge(current, defaults);
    const changed = diff(current, merged);

    if (!dryRun && changed.length > 0) {
        await backup(settingsPath);
        await fs.writeFile(settingsPath, JSON.stringify(merged, null, 2) + "\n");
    }

    return { statuslineChanged, settingsChanged: changed };
}

async function copyWithBackup(src, dst, dryRun) {
    const srcContent = await fs.readFile(src, "utf8");
    let dstContent;
    try { dstContent = await fs.readFile(dst, "utf8"); } catch { /* not exists */ }

    if (srcContent === dstContent) return false;

    if (!dryRun) {
        if (dstContent !== undefined) await fs.rename(dst, dst + ".bak");
        await fs.writeFile(dst, srcContent);
        await fs.chmod(dst, 0o755);
    }
    return true;
}

async function backup(filePath) {
    try {
        await fs.access(filePath);
        await fs.copyFile(filePath, filePath + ".bak");
    } catch { /* file doesn't exist, nothing to backup */ }
}

function deepMerge(a, b) {
    if (Array.isArray(b)) return b;
    if (typeof b !== "object" || b === null) return b;
    const out = { ...(a ?? {}) };
    for (const k of Object.keys(b)) out[k] = deepMerge(a?.[k], b[k]);
    return out;
}

function diff(before, after) {
    const changes = [];
    for (const k of Object.keys(after)) {
        if (JSON.stringify(before?.[k]) !== JSON.stringify(after[k])) changes.push(k);
    }
    return changes;
}
