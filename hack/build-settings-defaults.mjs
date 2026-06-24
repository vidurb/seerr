import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const settingsSource = fs.readFileSync(
  path.join(repoRoot, 'server/lib/settings/index.ts'),
  'utf-8'
);

const jsonPayloadMatch = settingsSource.match(
  /jsonPayload:\s*\n\s*'((?:\\'|[^'])*)'/
);
if (!jsonPayloadMatch) {
  throw new Error('Could not extract webhook jsonPayload from Settings constructor');
}
const webhookJsonPayload = jsonPayloadMatch[1];

/** Defaults mirror Settings constructor in server/lib/settings/index.ts */
export const settingsDefaults = {
  clientId: '',
  sessionSecret: '',
  vapidPrivate: '',
  vapidPublic: '',
  main: {
    apiKey: '',
    applicationTitle: 'Seerr',
    applicationUrl: '',
    cacheImages: false,
    defaultPermissions: 32,
    defaultQuotas: {
      movie: {},
      tv: {},
    },
    hideAvailable: false,
    hideBlocklisted: false,
    localLogin: true,
    mediaServerLogin: true,
    newPlexLogin: true,
    discoverRegion: '',
    streamingRegion: '',
    originalLanguage: '',
    blocklistRegion: '',
    blocklistLanguage: '',
    blocklistedTags: '',
    blocklistedTagsLimit: 50,
    mediaServerType: 4,
    partialRequestsEnabled: true,
    enableSpecialEpisodes: false,
    locale: 'en',
    youtubeUrl: '',
  },
  plex: {
    name: '',
    ip: '',
    port: 32400,
    useSsl: false,
    libraries: [],
  },
  jellyfin: {
    name: '',
    ip: '',
    port: 8096,
    useSsl: false,
    urlBase: '',
    externalHostname: '',
    jellyfinForgotPasswordUrl: '',
    libraries: [],
    serverId: '',
    apiKey: '',
  },
  tautulli: {},
  metadataSettings: {
    tv: 'tmdb',
    anime: 'tmdb',
  },
  radarr: [],
  sonarr: [],
  public: {
    initialized: false,
  },
  notifications: {
    agents: {
      email: {
        enabled: false,
        embedPoster: true,
        options: {
          userEmailRequired: false,
          emailFrom: '',
          smtpHost: '',
          smtpPort: 587,
          secure: false,
          ignoreTls: false,
          requireTls: false,
          allowSelfSigned: false,
          senderName: 'Seerr',
          usePublicLogo: false,
        },
      },
      discord: {
        enabled: false,
        embedPoster: true,
        types: 0,
        options: {
          webhookUrl: '',
          webhookRoleId: '',
          enableMentions: true,
          locale: 'en',
          useUserLocale: true,
        },
      },
      slack: {
        enabled: false,
        embedPoster: true,
        types: 0,
        options: {
          webhookUrl: '',
          locale: 'en',
        },
      },
      telegram: {
        enabled: false,
        embedPoster: true,
        types: 0,
        options: {
          botAPI: '',
          chatId: '',
          messageThreadId: '',
          sendSilently: false,
        },
      },
      pushbullet: {
        enabled: false,
        embedPoster: false,
        types: 0,
        options: {
          accessToken: '',
        },
      },
      pushover: {
        enabled: false,
        embedPoster: true,
        types: 0,
        options: {
          accessToken: '',
          userToken: '',
          sound: '',
        },
      },
      webhook: {
        enabled: false,
        embedPoster: true,
        types: 0,
        options: {
          webhookUrl: '',
          jsonPayload: webhookJsonPayload,
        },
      },
      webpush: {
        enabled: false,
        embedPoster: true,
        options: {},
      },
      gotify: {
        enabled: false,
        embedPoster: false,
        types: 0,
        options: {
          url: '',
          token: '',
          priority: 0,
          locale: 'en',
        },
      },
      ntfy: {
        enabled: false,
        embedPoster: true,
        types: 0,
        options: {
          url: '',
          topic: '',
          priority: 3,
          locale: 'en',
        },
      },
    },
  },
  jobs: {
    'plex-recently-added-scan': {
      schedule: '0 */5 * * * *',
    },
    'plex-full-scan': {
      schedule: '0 0 3 * * *',
    },
    'plex-watchlist-sync': {
      schedule: '0 */3 * * * *',
    },
    'plex-refresh-token': {
      schedule: '0 0 5 * * *',
    },
    'radarr-scan': {
      schedule: '0 0 4 * * *',
    },
    'sonarr-scan': {
      schedule: '0 30 4 * * *',
    },
    'availability-sync': {
      schedule: '0 0 5 * * *',
    },
    'download-sync': {
      schedule: '0 * * * * *',
    },
    'download-sync-reset': {
      schedule: '0 0 1 * * *',
    },
    'jellyfin-recently-added-scan': {
      schedule: '0 */5 * * * *',
    },
    'jellyfin-full-scan': {
      schedule: '0 0 3 * * *',
    },
    'image-cache-cleanup': {
      schedule: '0 0 5 * * *',
    },
    'process-blocklisted-tags': {
      schedule: '0 30 1 */7 * *',
    },
  },
  network: {
    csrfProtection: false,
    forceIpv4First: false,
    trustProxy: false,
    proxy: {
      enabled: false,
      hostname: '',
      port: 8080,
      useSsl: false,
      user: '',
      password: '',
      bypassFilter: '',
      bypassLocalAddresses: true,
    },
    dnsCache: {
      enabled: false,
      forceMinTtl: 0,
      forceMaxTtl: -1,
    },
    apiRequestTimeout: 10000,
  },
  oidcLogin: false,
  oidc: {
    providers: [],
  },
  migrations: [],
};

export function writeSettingsDefaults(outputPath) {
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(settingsDefaults, null, 2)}\n`, 'utf-8');
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const outputPath = path.join(
    repoRoot,
    'charts/seerr-chart/resources/settings-defaults.json'
  );
  writeSettingsDefaults(outputPath);
  console.log(`Wrote ${outputPath}`);
}
