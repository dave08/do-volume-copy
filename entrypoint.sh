#!/bin/sh

VOLUME_NAME=$1
REGION=$2
VOLUME_COPY_NAME=${3:-$1-dev}


post() {
	local JSON=$1
	local ENDPOINT=$2

	curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" -d $JSON "https://api.digitalocean.com/v2/$ENDPOINT"
}

get() {
	local ENDPOINT=$1

	curl -H "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/$ENDPOINT"
}

delete() {
	local ENDPOINT=$1

	curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/$ENDPOINT"
}

# Get volume id to copy using it's name
VOLUME_ID=$(get "volumes?name=$VOLUME_NAME&region=$REGION" | jq -r ".volumes[0].id")

# Create snapshot and retreive its id
SNAPSHOT_ID=$(post "{\"name\":\"$VOLUME_COPY_NAME\"}" "volumes/$VOLUME_ID/snapshots" | jq -r ".snapshot.id")

# Delete old staging volume copy
delete "volumes?name=$VOLUME_COPY_NAME&region=$REGION"

# Create staging volume from production snapshot
post "{\"name\":\"$VOLUME_COPY_NAME\",\"snapshot_id\":\"$SNAPSHOT_ID\"}" "volumes"

# Delete snapshot
delete "snapshots/$SNAPSHOT_ID"

# TODO: Check that each stage was completed...
