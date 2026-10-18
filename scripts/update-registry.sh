#!/usr/bin/env bash
# Upserts one connector entry into registry.json from a connector-released payload.
#
#   update-registry.sh <payload.json> <registry.json>
#
# The payload carries connector, version, image and spec, plus either
#   entry:    the registry entry without spec, already in the Airbyte format (synclet-io/connectors), or
#   metadata: the connector's snake_case meta.json (older senders),
# and the entry is written with breaking changes under releases.breakingChanges.
set -euo pipefail

PAYLOAD=$1
REGISTRY=$2

CONNECTOR=$(jq -r .connector "$PAYLOAD")
VERSION=$(jq -r .version "$PAYLOAD")
IMAGE=$(jq -r .image "$PAYLOAD")

case "$CONNECTOR" in
  source-*) ARRAY_KEY=sources ;;
  destination-*) ARRAY_KEY=destinations ;;
  *) echo "::error::Unknown connector type for: $CONNECTOR"; exit 1 ;;
esac

ENTRY=$(jq -c --arg image "$IMAGE" --arg version "$VERSION" '
  def nonempty: with_entries(select(.value != null and .value != "" and .value != {} and .value != []));
  if .entry != null then
    .entry + {dockerRepository: $image, dockerImageTag: $version, spec: .spec}
  else
    .metadata as $m
    | ($m.breaking_changes // {} | map_values({
        message: .message,
        migrationDocumentationUrl: .migration_documentation_url,
        upgradeDeadline: .upgrade_deadline
      } | nonempty)) as $breaking
    | {
        name: $m.name,
        dockerRepository: $image,
        dockerImageTag: $version,
        documentationUrl: $m.documentation_url,
        releaseStage: $m.release_stage,
        supportLevel: $m.support_level,
        sourceType: $m.source_type,
        iconUrl: $m.icon_url,
        license: $m.license,
        spec: .spec,
        releases: ({breakingChanges: $breaking, migrationDocumentationUrl: $m.migration_documentation_url} | nonempty),
        externalDocumentationUrls: $m.external_documentation_urls,
        tombstone: false
      }
      | with_entries(select(.value != null and .value != "" and .value != {}))
  end' "$PAYLOAD")

if ! echo "$ENTRY" | jq -e '.name and .spec.connectionSpecification' > /dev/null; then
  echo "::error::Payload for $CONNECTOR $VERSION has no name or no spec.connectionSpecification; registry.json left unchanged"
  exit 1
fi

jq --arg key "$ARRAY_KEY" --arg repo "$IMAGE" --argjson entry "$ENTRY" \
  '.[$key] = [.[$key][] | select(.dockerRepository != $repo)] + [$entry]' \
  "$REGISTRY" > "$REGISTRY.tmp"
mv "$REGISTRY.tmp" "$REGISTRY"
