# Synclet Connector Registry

Airbyte-format connector registry for Synclet. Served via GitHub Pages.

## How it works

1. A connector is released in [synclet-io/connectors](https://github.com/synclet-io/connectors) by pushing a tag
   `<connector>-v<version>` (e.g. `source-example-v0.1.0`). Connectors still in
   [synclet-io/synclet](https://github.com/synclet-io/synclet) release the same way from that repository.
2. The release workflow builds the Docker image, pushes it to GHCR, runs `spec` on the pushed image and only then
   sends a `connector-released` `repository_dispatch` event here
3. The `update-registry` workflow ([`scripts/update-registry.sh`](scripts/update-registry.sh)) replaces the
   connector's entry in `registry.json`
4. The `pages` workflow deploys the updated registry to GitHub Pages

### Dispatch payload

```json
{
  "event_type": "connector-released",
  "client_payload": {
    "connector": "source-example",
    "version": "0.1.0",
    "image": "ghcr.io/synclet-io/connectors/source-example",
    "spec": { "connectionSpecification": { ... } },
    "entry": { "name": "Example", "dockerRepository": "...", "dockerImageTag": "0.1.0", "releases": { ... }, ... },
    "metadata": { "name": "Example", "breaking_changes": { ... }, ... }
  }
}
```

`entry` is the finished registry entry without `spec`; when it is present it is written as is, with `spec`,
`dockerRepository` and `dockerImageTag` taken from the payload. Older senders send only `metadata` (the
connector's snake_case `meta.json`), which is mapped to the same format. Either way breaking changes are
written in the Airbyte form, under `releases`:

```json
"releases": {
  "breakingChanges": {
    "2.0.0": { "message": "...", "migrationDocumentationUrl": "https://...", "upgradeDeadline": "2027-01-31" }
  }
}
```

A payload without a `spec.connectionSpecification` is rejected and leaves `registry.json` unchanged.

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
      "dockerRepository": "ghcr.io/synclet-io/connectors/source-mysql",
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
