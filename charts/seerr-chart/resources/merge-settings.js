#!/usr/bin/env node
'use strict';

const fs = require('fs');

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, 'utf8'));
}

function isPlainObject(value) {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

// Recursively merges `overrides` onto `base`. Objects are merged key by key;
// arrays and scalars in `overrides` replace the corresponding value in `base`
// wholesale, so keys absent from `overrides` are always left untouched.
function deepMerge(base, overrides) {
  if (!isPlainObject(overrides)) {
    return overrides;
  }
  const result = isPlainObject(base) ? { ...base } : {};
  for (const key of Object.keys(overrides)) {
    const overrideValue = overrides[key];
    result[key] =
      isPlainObject(overrideValue) && isPlainObject(result[key])
        ? deepMerge(result[key], overrideValue)
        : overrideValue;
  }
  return result;
}

const [, , livePath, defaultsPath, overridesPath, outputPath] = process.argv;

if (!livePath || !defaultsPath || !overridesPath || !outputPath) {
  console.error(
    'usage: merge-settings.js <live.json> <defaults.json> <overrides.json> <output.json>'
  );
  process.exit(1);
}

try {
  // Live settings.json is the merge base once it exists, so anything set
  // through the UI (Plex library scans, Sonarr/Radarr sync state, etc.)
  // survives. Chart defaults are only the base for a brand new install.
  const base =
    fs.existsSync(livePath) && fs.statSync(livePath).size > 0
      ? readJson(livePath)
      : readJson(defaultsPath);
  const overrides = readJson(overridesPath);
  const merged = deepMerge(base, overrides);

  fs.writeFileSync(outputPath, JSON.stringify(merged, null, 1) + '\n');
} catch (error) {
  console.error(`Failed to merge Seerr settings: ${error.message}`);
  process.exit(1);
}
