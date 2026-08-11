import { readFileSync } from 'node:fs';
import path from 'node:path';

import { REPO_ROOT } from './paths.ts';

/** Best-effort load of repo-root `.env` into process.env (does not override existing keys). */
export function loadRootEnv(): void {
  const envPath = path.join(REPO_ROOT, '.env');
  let text: string;
  try {
    text = readFileSync(envPath, 'utf8');
  } catch {
    return;
  }

  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq <= 0) continue;
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}
