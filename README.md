# Synclet Connector Registry

Airbyte-format connector registry for Synclet. Served via GitHub Pages.

## How it works

1. A connector is released in [synclet-io/synclet](https://github.com/synclet-io/synclet) by pushing a tag (e.g. `source-mysql-v1.0.0`)
2. The release workflow builds the Docker image, pushes to GHCR, and sends a `repository_dispatch` event here
3. The `update-registry` workflow pulls the image, extracts the connector spec, and updates `registry.json`
4. The `pages` workflow deploys the updated registry to GitHub Pages

## Registry URL

```
https://synclet-io.github.io/synclet-connector-registry/registry.json
```

## Format

The registry follows the [Airbyte OSS registry format](https://connectors.airbyte.com/files/registries/v0/oss_registry.json):

```json
{
  "sources": [
    {
      "name": "source-mysql",
      "dockerRepository": "ghcr.io/synclet-io/synclet/source-mysql",
      "dockerImageTag": "1.0.0",
      "spec": { "connectionSpecification": { ... } },
      ...
    }
  ],
  "destinations": [...]
}
```

## Adding to Synclet

In the Synclet UI, add a repository with the URL above. The system will sync connectors automatically every hour.
