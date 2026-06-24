#!/usr/bin/env node
/**
 * Regenerates charts/seerr-chart/resources/settings-defaults.json from the
 * Settings class constructor defaults in server/lib/settings/index.ts.
 *
 * Uses hack/build-settings-defaults.mjs (inline defaults + webhook payload
 * extracted from source). When dependencies are installed, you can optionally
 * verify output with:
 *
 *   pnpm exec ts-node -r tsconfig-paths/register --project server/tsconfig.json \
 *     -e "const Settings = require('./server/lib/settings/index.ts').default; ..."
 *
 * Usage (from repo root):
 *   node hack/generate-settings-defaults.mjs
 */
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { writeSettingsDefaults } from './build-settings-defaults.mjs';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputPath = path.join(
  repoRoot,
  'charts/seerr-chart/resources/settings-defaults.json'
);

writeSettingsDefaults(outputPath);
console.log(`Wrote ${outputPath}`);
