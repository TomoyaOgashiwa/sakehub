#!/usr/bin/env node
/* global console, process */
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
const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
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
  if (typeof d.slug !== 'string' || !SLUG_PATTERN.test(d.slug)) {
    throw new Error(`invalid slug: ${JSON.stringify(d?.slug)}`);
  }
  const out = path.join(OUT, `${d.slug}.json`);
  if (path.dirname(path.resolve(out)) !== path.resolve(OUT)) {
    throw new Error(`path escape for slug: ${d.slug}`);
  }
  if (existsSync(out) && !force) {
    skipped++;
    continue;
  }
  writeFileSync(out, JSON.stringify(d, null, 2) + '\n', 'utf8');
  written++;
}
console.log(`wrote ${written}, skipped ${skipped} (existing)`);
