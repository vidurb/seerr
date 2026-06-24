#!/usr/bin/env node
/**
 * Regenerates charts/seerr-chart/values.schema.json settings.data properties
 * from AllSettings top-level keys and OpenAPI component schema names in seerr-api.yml.
 *
 * Usage (from repo root):
 *   node hack/generate-values-schema.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'js-yaml';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const apiSpecPath = path.join(repoRoot, 'seerr-api.yml');
const schemaPath = path.join(repoRoot, 'charts/seerr-chart/values.schema.json');

const allSettingsKeys = [
  'clientId',
  'sessionSecret',
  'vapidPublic',
  'vapidPrivate',
  'main',
  'plex',
  'jellyfin',
  'tautulli',
  'metadataSettings',
  'radarr',
  'sonarr',
  'public',
  'notifications',
  'jobs',
  'network',
  'oidcLogin',
  'oidc',
  'migrations',
];

const openapiComponentMap = {
  main: 'MainSettings',
  plex: 'PlexSettings',
  jellyfin: 'JellyfinSettings',
  tautulli: 'TautulliSettings',
  metadataSettings: 'MetadataSettings',
  radarr: 'RadarrSettings',
  sonarr: 'SonarrSettings',
  public: 'PublicSettings',
  network: 'NetworkSettings',
};

const apiSpec = yaml.load(fs.readFileSync(apiSpecPath, 'utf-8'));
const components = apiSpec?.components?.schemas ?? {};

function openapiTypeToJsonSchema(schema) {
  if (!schema || typeof schema !== 'object') {
    return { type: 'object' };
  }
  if (schema.$ref) {
    const name = schema.$ref.replace('#/components/schemas/', '');
    return openapiTypeToJsonSchema(components[name]);
  }
  if (schema.type === 'array') {
    return {
      type: 'array',
      items: openapiTypeToJsonSchema(schema.items ?? {}),
    };
  }
  if (schema.type === 'object' || schema.properties) {
    const properties = {};
    for (const [key, value] of Object.entries(schema.properties ?? {})) {
      properties[key] = openapiTypeToJsonSchema(value);
    }
    return { type: 'object', properties };
  }
  if (schema.type === 'boolean') return { type: 'boolean' };
  if (schema.type === 'integer' || schema.type === 'number') return { type: 'number' };
  return { type: 'string' };
}

const dataProperties = {};
for (const key of allSettingsKeys) {
  if (key === 'radarr' || key === 'sonarr' || key === 'migrations') {
    dataProperties[key] = openapiTypeToJsonSchema({
      type: 'array',
      items: components[openapiComponentMap[key]]
        ? { $ref: `#/components/schemas/${openapiComponentMap[key]}` }
        : { type: 'string' },
    });
    continue;
  }
  if (key === 'notifications' || key === 'jobs' || key === 'oidc') {
    dataProperties[key] = { type: 'object' };
    continue;
  }
  if (key === 'oidcLogin') {
    dataProperties[key] = { type: 'boolean' };
    continue;
  }
  if (key === 'metadataSettings') {
    dataProperties[key] = {
      type: 'object',
      properties: {
        tv: { type: 'string', enum: ['tmdb', 'tvdb'] },
        anime: { type: 'string', enum: ['tmdb', 'tvdb'] },
      },
    };
    continue;
  }
  const componentName = openapiComponentMap[key];
  if (componentName && components[componentName]) {
    dataProperties[key] = openapiTypeToJsonSchema(components[componentName]);
  } else {
    dataProperties[key] = { type: 'string' };
  }
}

const schema = {
  $schema: 'http://json-schema.org/draft-07/schema#',
  type: 'object',
  properties: {
    settings: {
      type: 'object',
      properties: {
        management: {
          type: 'string',
          enum: ['ui', 'helm'],
          description:
            'How settings.json is managed. ui: app on PVC. helm: init container applies Helm values on pod start.',
        },
        existingSecret: {
          type: 'string',
          description: 'Existing Secret name containing settings.json (helm mode only).',
        },
        existingSecretKey: {
          type: 'string',
          default: 'settings.json',
          description: 'Key in existingSecret that holds settings.json.',
        },
        data: {
          type: 'object',
          description: 'Partial AllSettings overrides merged into chart defaults.',
          properties: dataProperties,
          additionalProperties: false,
        },
      },
      required: ['management'],
    },
  },
};

fs.writeFileSync(schemaPath, `${JSON.stringify(schema, null, 2)}\n`, 'utf-8');
console.log(`Wrote ${schemaPath}`);
