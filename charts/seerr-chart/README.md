# seerr-chart

![Version: 3.9.0](https://img.shields.io/badge/Version-3.9.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v3.3.0](https://img.shields.io/badge/AppVersion-v3.3.0-informational?style=flat-square)

Seerr helm chart for Kubernetes

**Homepage:** <https://github.com/seerr-team/seerr>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Seerr Team |  | <https://github.com/orgs/seerr-team/people> |

## Source Code

* <https://github.com/seerr-team/seerr/tree/main/charts/seerr-chart>

## Requirements

Kubernetes: `>=1.23.0-0`

## Installation

Refer to [Seerr kubernetes documentation](https://docs.seerr.dev/getting-started/kubernetes)

## Update Notes

### Updating to 3.0.0

Nothing has changed; we just rebranded the `jellyseerr` Helm chart to `seerr` 🥳 refer to our [Migration guide](https://docs.seerr.dev/migration-guide).

### Updating to 2.7.0

Seerr is a stateful application and it is not designed to have multiple replicas. In version 2.7.0 we address this by:

- replacing `Deployment` with `StatefulSet`
- removing `replicaCount` value

If `replicaCount` value was used - remove it. Helm update should work fine after that.

## Settings management

Seerr stores application configuration in `settings.json` under the config volume (`/app/config/settings.json`).

| `settings.management` | Behavior |
| --- | --- |
| `ui` (default) | Seerr reads and writes `settings.json` on the PVC. Use the setup wizard or Settings UI. |
| `helm` | An init container deep-merges Helm-declared overrides onto `settings.json` on **every pod start**. |

In `helm` mode, the init container (`apply-settings`) merges rather than overwrites: it reads the live `settings.json` already on the PVC (or, on a brand new install, the chart's bundled defaults), then deep-merges the Helm-declared overrides on top and writes the result back. Keys declared in `settings.data`/`secretRefs` always come from Helm; every other key - including values Seerr only discovers live, like `plex.libraries`, `plex.machineId`, or Sonarr/Radarr sync state - is left exactly as the app last wrote it. Array fields (`radarr`, `sonarr`, `migrations`, `oidc.providers`) still replace entirely when declared in `settings.data`, same as before.

### Helm-managed settings

Set `settings.management` to `helm` and provide overrides under `settings.data`. These are deep-merged onto the live `settings.json` at pod start; the bundled defaults from `resources/settings-defaults.json` (regenerate with `node hack/generate-settings-defaults.mjs` in the Seerr repo) are only used as the merge base on a brand new install.

```yaml
settings:
  management: helm
  data:
    public:
      initialized: true
    main:
      applicationTitle: Seerr
      applicationUrl: https://requests.example.com
    network:
      trustProxy: true
    oidcLogin: true
    oidc:
      providers:
        - slug: pocketid
          name: Pocket ID
          issuerUrl: https://auth.example.com
          clientId: ""
          clientSecret: ""
          logo: ""
          newUserLogin: true
```

Sensitive values (API keys, SMTP passwords, OIDC client secrets, etc.) should use `settings.existingSecret` pointing to a Kubernetes Secret (for example SOPS-encrypted in GitOps) instead of inline `settings.data`:

```yaml
settings:
  management: helm
  existingSecret: seerr-settings
  existingSecretKey: settings.overrides.json
```

The secret should contain the overrides patch (same partial `AllSettings` shape as `settings.data`), not a full `settings.json` - it gets deep-merged onto the live config the same way `settings.data` does.

**Notes:**

- Array fields (`radarr`, `sonarr`, `migrations`, `oidc.providers`) are replaced entirely when overridden in `settings.data`.
- `oidcLogin` and `oidc` are fork-specific settings keys (not in upstream OpenAPI) for OIDC authentication.
- Discover settings are not part of `settings.json` and remain UI-managed.
- Changing Helm values requires a pod restart to re-run the init container (consider [Stakater Reloader](https://github.com/stakater/Reloader) for automatic rollouts).
- Removing a key from `settings.data` does not retroactively clear it from the live `settings.json` - the last-applied value sticks until changed via the UI/API or explicitly overridden again.
- Database connection is configured separately via `extraEnv` (`DB_TYPE`, `DB_HOST`, etc.), not `settings.json`.

Run chart tests: `./ci/test-settings.sh`

### Updating to 3.9.0

`settings.management: helm` now deep-merges Helm-declared overrides onto the live `settings.json` on every pod start, instead of overwriting the whole file. This preserves values Seerr only discovers live (Plex library scans, `plex.machineId`, Sonarr/Radarr sync state, etc.) across pod restarts.

- The chart secret key changed from `settings.json` to `settings.overrides.json`, and the `existingSecretKey` default changed to match - it now holds only the overrides patch, not a full settings file.
- A new `<release>-settings-defaults` ConfigMap is rendered in `helm` mode (holds the bundled defaults and merge script); no action needed, but note it as an additional resource if you track chart output.
- The `apply-settings` init container now runs the Seerr image (for Node) instead of the busybox `volumePermissions` image; give it enough resources via `settings.applyResources` if you've constrained cluster defaults.

### Updating to 3.8.1

Adds OIDC settings keys (`oidcLogin`, `oidc.providers`) to Helm-managed `settings.json`.

### Updating to 3.8.0

Adds Helm-managed `settings.json` via `settings.management` and `settings.data` values.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| config | object | `{"persistence":{"accessModes":["ReadWriteOnce"],"annotations":{},"existingClaim":"","name":"","size":"5Gi","storageClass":"","subPath":"","volumeName":""}}` | Creating PVC to store configuration |
| config.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes of persistent disk |
| config.persistence.annotations | object | `{}` | Annotations for PVCs |
| config.persistence.existingClaim | string | `""` | Specify an existing `PersistentVolumeClaim` to use. If this value is provided, the default PVC will not be created |
| config.persistence.name | string | `""` | Config name |
| config.persistence.size | string | `"5Gi"` | Size of persistent disk |
| config.persistence.storageClass | string | `""` | Storage class for the PVC. Set to "-" to disable dynamic provisioning. Uses default storage class if no value is provided |
| config.persistence.subPath | string | `""` | Subpath of the pvc which should be mounted |
| config.persistence.volumeName | string | `""` | Name of the permanent volume to reference in the claim. Can be used to bind to existing volumes. |
| extraEnv | list | `[]` | Environment variables to add to the seerr pods |
| extraEnvFrom | list | `[]` | Environment variables from secrets or configmaps to add to the seerr pods |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"ghcr.io"` |  |
| image.repository | string | `"seerr-team/seerr"` |  |
| image.sha | string | `""` |  |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.ingressClassName | string | `""` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| probes.livenessProbe | object | `{"initialDelaySeconds":20,"periodSeconds":15,"timeoutSeconds":3}` | Configure liveness probe |
| probes.readinessProbe | object | `{"initialDelaySeconds":60,"periodSeconds":15,"timeoutSeconds":3}` | Configure readiness probe |
| probes.startupProbe | string | `nil` | Configure startup probe |
| resources | object | `{}` |  |
| route.main.additionalRules | list | `[]` |  |
| route.main.annotations | object | `{}` |  |
| route.main.apiVersion | string | `"gateway.networking.k8s.io/v1"` | Set the route apiVersion, e.g. gateway.networking.k8s.io/v1 or gateway.networking.k8s.io/v1alpha2 |
| route.main.enabled | bool | `false` | Enables or disables the Gateway API route |
| route.main.filters | list | `[]` |  |
| route.main.hostnames | list | `[]` |  |
| route.main.httpsRedirect | bool | `false` | To redirect to HTTPS, create a new route object under the main route and enable this option. This should only be used with HTTP-like routes, such as HTTPRoute or GRPCRoute. [Reference]( https://gateway-api.sigs.k8s.io/guides/http-redirect-rewrite/ ) |
| route.main.kind | string | `"HTTPRoute"` | Set the route kind. Note that experimental kinds require changing `apiVersion` |
| route.main.labels | object | `{}` |  |
| route.main.matches[0].path.type | string | `"PathPrefix"` |  |
| route.main.matches[0].path.value | string | `"/"` |  |
| route.main.parentRefs | list | `[]` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.privileged | bool | `false` |  |
| securityContext.readOnlyRootFilesystem | bool | `false` |  |
| securityContext.runAsGroup | int | `1000` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `1000` |  |
| securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| service.annotations | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| settings | object | `{"applyResources":{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}},"data":{},"existingSecret":"","existingSecretKey":"settings.overrides.json","management":"ui"}` | Seerr settings.json management |
| settings.applyResources | object | `{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resources for the apply-settings init container (helm mode only) |
| settings.data | object | `{}` | Partial AllSettings overrides, deep-merged onto the live settings.json (helm mode) |
| settings.existingSecret | string | `""` | Existing Secret containing the settings overrides patch (helm mode) |
| settings.existingSecretKey | string | `"settings.overrides.json"` | Key in existingSecret |
| settings.management | string | `"ui"` | `ui` or `helm` — who controls settings.json |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` | Additional volumeMounts on the output StatefulSet definition. |
| volumes | list | `[]` | Additional volumes on the output StatefulSet definition. |
