#!/usr/bin/env node
/**
 * One-shot helper: write DrinkSeed JSON files from a JSON array on stdin
 * or from a file path argument. Does not overwrite existing files unless
 * --force is passed.
 *
 * Usage: node scripts/write-drinks.mjs [--force] [path-to-array.json]
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT = path.join(ROOT, 'data', 'drinks');
mkdirSync(OUT, { recursive: true });

const args = process.argv.slice(2);
const force = args.includes('--force');
const fileArg = args.find((a) => a !== '--force');

const raw = fileArg ? readFileSync(fileArg, 'utf8') : readFileSync(0, 'utf8');
const drinks = JSON.parse(raw);
if (!Array.isArray(drinks)) throw new Error('expected JSON array');

let written = 0;
let skipped = 0;
for (const d of drinks) {
  const out = path.join(OUT, `${d.slug}.json`);
  if (existsSync(out) && !force) {
    skipped++;
    continue;
  }
  writeFileSync(out, JSON.stringify(d, null, 2) + '\n', 'utf8');
  written++;
}
console.log(`wrote ${written}, skipped ${skipped} (existing)`);
