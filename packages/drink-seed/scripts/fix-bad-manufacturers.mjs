#!/usr/bin/env node
/* global console, process */
/**
 * @deprecated One-shot migration helper from the Phase1 seed expansion.
 *
 * Do NOT use this as an ongoing data pipeline.
 * - Source of truth: `data/drinks/*.json` only
 * - Quality gate: `pnpm seed:drinks:validate` (`assertManufacturerQuality` in seed-utils)
 * - Prefer editing JSON directly, then validate + build
 *
 * This file is kept only so historical PR discussion links remain meaningful.
 * It no longer writes `data/batches/` (batches are gitignored / non-canonical).
 */
console.error(
  [
    'fix-bad-manufacturers.mjs is deprecated.',
    'Edit packages/drink-seed/data/drinks/<slug>.json directly,',
    'then run: pnpm seed:drinks:validate && pnpm seed:drinks:build',
  ].join('\n'),
);
process.exit(1);
