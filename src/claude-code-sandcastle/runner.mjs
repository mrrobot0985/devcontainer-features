#!/usr/bin/env node
/**
 * Sandcastle Runner
 * Deterministic task router + .scratch/ I/O for local-markdown tracker.
 */

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync, mkdirSync } from 'fs';
import { dirname, join, basename } from 'path';
import { execSync } from 'child_process';

const RALPH_DIR = '.ralph';
const STATE_FILE = join(RALPH_DIR, 'state.json');

// ─── .scratch/ I/O helpers ────────────────────────────────────────────────────

function readMap(effortSlug) {
    const mapPath = `.scratch/${effortSlug}/map.md`;
    if (!existsSync(mapPath)) return null;
    return readFileSync(mapPath, 'utf-8');
}

function listTickets(effortSlug) {
    const issuesDir = `.scratch/${effortSlug}/issues`;
    if (!existsSync(issuesDir)) return [];
    return readdirSync(issuesDir)
        .filter(f => f.endsWith('.md'))
        .map(f => join(issuesDir, f))
        .sort();
}

function parseTicket(filePath) {
    const content = readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');
    const ticket = {
        path: filePath,
        number: parseInt(basename(filePath).split('-')[0], 10),
        status: 'open',
        type: 'task',
        blockedBy: [],
        content,
    };

    for (const line of lines) {
        if (line.startsWith('Status:')) {
            ticket.status = line.replace('Status:', '').trim();
        } else if (line.startsWith('Type:')) {
            ticket.type = line.replace('Type:', '').trim();
        } else if (line.startsWith('Blocked by:')) {
            const raw = line.replace('Blocked by:', '').trim();
            if (raw) {
                ticket.blockedBy = raw.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n));
            }
        }
    }
    return ticket;
}

function findFrontier(effortSlug) {
    const tickets = listTickets(effortSlug).map(parseTicket);
    return tickets.filter(t => {
        if (t.status !== 'open') return false;
        if (t.status === 'claimed') return false;
        // Check blockers: all blocked-by tickets must be resolved
        for (const blockerNum of t.blockedBy) {
            const blocker = tickets.find(bt => bt.number === blockerNum);
            if (!blocker || blocker.status !== 'resolved') return false;
        }
        return true;
    });
}

function claimTicket(effortSlug, ticketNumber) {
    const issuesDir = `.scratch/${effortSlug}/issues`;
    const files = readdirSync(issuesDir).filter(f => f.endsWith('.md')).sort();
    for (const file of files) {
        if (file.startsWith(String(ticketNumber).padStart(2, '0'))) {
            const path = join(issuesDir, file);
            let content = readFileSync(path, 'utf-8');
            content = content.replace(/^Status:.*$/m, 'Status: claimed');
            writeFileSync(path, content);
            return true;
        }
    }
    return false;
}

function resolveTicket(effortSlug, ticketNumber, answer, contextPointer) {
    const issuesDir = `.scratch/${effortSlug}/issues`;
    const files = readdirSync(issuesDir).filter(f => f.endsWith('.md')).sort();
    for (const file of files) {
        if (file.startsWith(String(ticketNumber).padStart(2, '0'))) {
            const path = join(issuesDir, file);
            let content = readFileSync(path, 'utf-8');
            content = content.replace(/^Status:.*$/m, 'Status: resolved');
            if (answer) {
                content += `\n\n## Answer\n\n${answer}\n`;
            }
            writeFileSync(path, content);

            // Update map Decisions-so-far
            if (contextPointer) {
                appendToMapDecisions(effortSlug, contextPointer);
            }
            return true;
        }
    }
    return false;
}

function appendToMapDecisions(effortSlug, decisionLine) {
    const mapPath = `.scratch/${effortSlug}/map.md`;
    if (!existsSync(mapPath)) return false;
    let content = readFileSync(mapPath, 'utf-8');
    const decisionsMarker = '## Decisions so far';
    const idx = content.indexOf(decisionsMarker);
    if (idx === -1) return false;
    const endOfSection = content.indexOf('##', idx + decisionsMarker.length);
    const insertPos = endOfSection === -1 ? content.length : endOfSection;
    const line = `- ${decisionLine}\n`;
    content = content.slice(0, insertPos) + line + content.slice(insertPos);
    writeFileSync(mapPath, content);
    return true;
}

function frontierCount(effortSlug) {
    return findFrontier(effortSlug).length;
}

// ─── Task routing ────────────────────────────────────────────────────────────

function runImplementTask(effortSlug) {
    const frontier = findFrontier(effortSlug);
    if (frontier.length === 0) {
        console.log('No frontier tickets found.');
        return 0;
    }

    const ticket = frontier[0];
    console.log(`Claiming ticket ${ticket.number}: ${basename(ticket.path)}`);
    claimTicket(effortSlug, ticket.number);

    // Skip HITL-only types
    if (ticket.type === 'grilling') {
        console.log(`Skipping HITL-only ticket type: ${ticket.type}`);
        return 0;
    }

    if (ticket.type === 'prototype') {
        const degraded = process.env.SANDCASTLE_DEGRADED_PROTOTYPE === 'true';
        if (!degraded) {
            console.log('Skipping prototype — degraded mode disabled. Set SANDCASTLE_DEGRADED_PROTOTYPE=true to enable.');
            return 0;
        }
        console.log('Running prototype in degraded AFK mode...');
        // In a real environment, would invoke: claude --no-interactive --skill ~/.claude/skills/prototype-headless/SKILL.md
    }

    if (ticket.type === 'task' || ticket.type === 'research') {
        console.log(`Running implement-headless for ticket ${ticket.number}...`);
        try {
            execSync(`claude --no-interactive --skill ~/.claude/skills/implement-headless/SKILL.md ${ticket.path}`, {
                stdio: 'inherit',
                timeout: 600000, // 10 minutes
            });
        } catch (err) {
            console.error(`Implement failed for ticket ${ticket.number}:`, err.message);
            return 1;
        }
    }

    const answer = `Implemented ticket ${ticket.number} via implement-headless.`;
    const contextPointer = `[Ticket ${ticket.number}](issues/${String(ticket.number).padStart(2, '0')}-${basename(ticket.path).slice(3)}) — ${answer}`;
    resolveTicket(effortSlug, ticket.number, answer, contextPointer);
    console.log(`Resolved ticket ${ticket.number}`);
    return 0;
}

function runReviewTask(effortSlug) {
    console.log(`Running code-review-headless for effort: ${effortSlug}`);
    try {
        execSync(`claude --no-interactive --skill ~/.claude/skills/code-review-headless/SKILL.md ${effortSlug}`, {
            stdio: 'inherit',
            timeout: 300000, // 5 minutes
        });
    } catch (err) {
        console.error(`Review failed:`, err.message);
        return 1;
    }
    return 0;
}

// ─── CLI ─────────────────────────────────────────────────────────────────────

const [,, cmd, arg] = process.argv;

switch (cmd) {
    case 'implement': {
        const effortSlug = arg || 'default';
        process.exit(runImplementTask(effortSlug));
    }
    case 'review': {
        const effortSlug = arg || 'default';
        process.exit(runReviewTask(effortSlug));
    }
    case 'frontier-count': {
        const effortSlug = arg || 'default';
        console.log(frontierCount(effortSlug));
        process.exit(0);
    }
    case 'list-frontier': {
        const effortSlug = arg || 'default';
        const frontier = findFrontier(effortSlug);
        for (const t of frontier) {
            console.log(`${String(t.number).padStart(2, '0')}: ${t.status} (${t.type}) — ${basename(t.path)}`);
        }
        process.exit(0);
    }
    default:
        console.error(`Usage: runner.mjs {implement|review|frontier-count|list-frontier} <effort-slug>`);
        process.exit(1);
}
