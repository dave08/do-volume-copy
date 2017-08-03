#!/bin/sh

VOLUME_NAME=$1
REGION=$2
VOLUME_COPY_NAME=${3:-$1-dev}


post() {
	local JSON=$1
	local ENDPOINT=$2

	curl -sSX POST -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" -d $JSON "https://api.digitalocean.com/v2/$ENDPOINT"
}

get() {
	local ENDPOINT=$1

	curl -sSH "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/$ENDPOINT"
}

delete() {
	local ENDPOINT=$1

	curl -sSX DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/$ENDPOINT"
}

# Get volume id to copy using it's name
VOLUME_ID=$(get "volumes?name=$VOLUME_NAME&region=$REGION" | jq -r ".volumes[0].id")
echo "Got volume $VOLUME_NAME: $VOLUME_ID"

# Create snapshot and retreive its id
SNAPSHOT_ID=$(post "{\"name\":\"$VOLUME_COPY_NAME\"}" "volumes/$VOLUME_ID/snapshots" | jq -r ".snapshot.id")
echo "Created snapshot $SNAPSHOT_ID"

# Detach old staging volume
DROPLET_ATTACHED=$(get "volumes?name=$VOLUME_COPY_NAME&region=$REGION" | jq ".volumes[0].droplet_ids[0]")
echo "volume: $VOLUME_COPY_NAME attached to: $DROPLET_ATTACHED"
post "{\"type\":\"detach\",\"droplet_id\":$DROPLET_ATTACHED,\"volume_name\":\"$VOLUME_COPY_NAME\",\"region\":\"fra1\"}" "volumes/actions"
echo "Volume detached from droplet."

# Delete old staging volume copy
delete "volumes?name=$VOLUME_COPY_NAME&region=$REGION"
echo "Deleted old volume $VOLUME_COPY_NAME"

# Create staging volume from production snapshot
post "{\"name\":\"$VOLUME_COPY_NAME\",\"snapshot_id\":\"$SNAPSHOT_ID\"}" "volumes"
echo "Created copied volume from snapshot"

# Delete snapshot
delete "snapshots/$SNAPSHOT_ID"
echo "Deleted snapshot"

# TODO: Check that each stage was completed...
