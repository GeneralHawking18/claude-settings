#!/usr/bin/env node
import { install } from "../src/install.js";

const cmd    = process.argv[2] ?? "install";
const dryRun = process.argv.includes("--dry-run");

if (cmd === "install") {
    const r = await install({ dryRun });
    const prefix = dryRun ? "[dry-run]" : "[ok]";
    if (r.statuslineChanged) console.log(prefix, "statusline.js →", "~/.claude/statusline.js");
    if (r.settingsChanged.length > 0) {
        console.log(prefix, "settings.json changed keys:", r.settingsChanged.join(", "));
    } else {
        console.log(prefix, "Already up to date.");
    }
} else if (cmd === "--help" || cmd === "-h") {
    console.log("Usage: claude-settings [install] [--dry-run]");
} else {
    console.error("Unknown command:", cmd);
    process.exit(2);
}
