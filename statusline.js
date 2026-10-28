#!/usr/bin/env node

// ANSI helpers
const RESET      = '\x1b[0m';
const WHITE_FG   = '\x1b[97m';

// True-color background via ANSI 24-bit escape
function bg(hex) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `\x1b[48;2;${r};${g};${b}m`;
}

const BG_NAVY     = bg('#1a1a2e'); // section 1 — model + context dot
const BG_TEAL     = bg('#0d2137'); // section 2 — repo + branch
const BG_DKGREEN  = bg('#1a2e1a'); // section 3 — context % (< 60%)
const BG_YELLOW   = bg('#3a3000'); // section 3 — context % (60–79%)
const BG_RED      = bg('#3a0000'); // section 3 — context % (>= 80%)
const BG_PURPLE   = bg('#2e1a3a'); // section 4 — rate limit

function section(bgColor, text) {
  return `${bgColor}${WHITE_FG} ${text} ${RESET}`;
}

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { raw += chunk; });
process.stdin.on('end', () => {
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    process.stdout.write('claude\n');
    process.exit(0);
  }

  const parts = [];

  // ── Section 1: colored dot + model name ─────────────────────────────────────
  const modelName  = data?.model?.display_name ?? 'Claude';
  const usedPct    = data?.context_window?.used_percentage ?? null;

  // Dot color based on context usage
  let dot;
  if (usedPct == null) {
    dot = '●'; // neutral white — no data yet
  } else if (usedPct < 50) {
    dot = '\x1b[32m●\x1b[97m'; // green
  } else if (usedPct <= 80) {
    dot = '\x1b[33m●\x1b[97m'; // yellow
  } else {
    dot = '\x1b[31m●\x1b[97m'; // red
  }

  parts.push(section(BG_NAVY, `${dot} ${modelName}`));

  // ── Section 2: current repo/folder + git branch ──────────────────────────────
  const dir = data?.workspace?.current_dir ?? data?.cwd ?? process.cwd();
  const { execSync } = require('child_process');
  const git = cmd => { try { return execSync(`git -C "${dir}" ${cmd}`, { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch { return ''; } };
  const repo = require('path').basename(git('rev-parse --show-toplevel') || dir);
  const branch = git('branch --show-current');
  parts.push(section(BG_TEAL, `\uD83D\uDCC1 ${repo}${branch ? ` (${branch})` : ''}`));

  // ── Section 3: context usage percentage ─────────────────────────────────────
  if (usedPct != null) {
    const pct = Math.min(100, Math.max(0, usedPct));
    let ctxBg;
    if (pct >= 80) {
      ctxBg   = BG_RED;
    } else if (pct >= 60) {
      ctxBg   = BG_YELLOW;
    } else {
      ctxBg   = BG_DKGREEN;
    }

    const u    = data.context_window.current_usage ?? {};
    const used = (u.input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0) + (u.cache_read_input_tokens ?? 0);
    const size = data.context_window.context_window_size;
    const k = n => n >= 1e6 ? `${+(n / 1e6).toFixed(1)}M` : `${Math.round(n / 1000)}k`;
    const tokLabel = size ? ` ${k(used)}/${k(size)}` : '';
    parts.push(section(ctxBg, `${Math.round(pct)}%${tokLabel}`));
  }

  // ── Section 4: 5-hour rate limit usage ──────────────────────────────────────
  const fiveHourPct = data?.rate_limits?.five_hour?.used_percentage ?? null;
  if (fiveHourPct != null) {
    const pct = Math.min(100, Math.max(0, fiveHourPct));
    let pctColor;
    if (pct < 50) {
      pctColor = '\x1b[32m'; // green
    } else if (pct <= 80) {
      pctColor = '\x1b[33m'; // yellow
    } else {
      pctColor = '\x1b[31m'; // red
    }
    const pctLabel = `${pctColor}${Math.round(pct)}%\x1b[97m`;
    parts.push(section(BG_PURPLE, `5h ${pctLabel}`));
  }

  process.stdout.write(parts.join(' ') + '\n');
});
