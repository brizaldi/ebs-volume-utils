#!/bin/bash

# File containing the list of volume IDs
VOLUME_FILE=$1
# File to store the created snapshot IDs
SNAPSHOT_OUTPUT_FILE="snapshot_ids.txt"

# Check if file is provided
if [ -z "$VOLUME_FILE" ]; then
  echo "Usage: $0 <volume_ids_file>"
  exit 1
fi

# Check if file exists
if [ ! -f "$VOLUME_FILE" ]; then
  echo "File $VOLUME_FILE not found!"
  exit 1
fi

# Empty the output file if it exists, or create a new one
> "$SNAPSHOT_OUTPUT_FILE"

# Iterate through each volume ID in the file
while IFS= read -r VOLUME_ID; do
  if [ -z "$VOLUME_ID" ]; then
    continue  # Skip empty lines
  fi
  
  echo "Processing volume: $VOLUME_ID"

  # Create snapshot
  SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id "$VOLUME_ID" --description "Snapshot of volume $VOLUME_ID" --query 'SnapshotId' --output text)
  
  if [ $? -ne 0 ]; then
    echo "Failed to create snapshot for volume $VOLUME_ID"
    continue
  fi
  
  echo "Snapshot $SNAPSHOT_ID created for volume $VOLUME_ID"

  # Write the Snapshot ID to the output file
  echo "$SNAPSHOT_ID" >> "$SNAPSHOT_OUTPUT_FILE"
  
  # Get tags from the volume
  TAGS_JSON=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query 'Volumes[0].Tags' --output json)

  if [ "$TAGS_JSON" != "null" ]; then
    # Create tags for the snapshot
    aws ec2 create-tags --resources "$SNAPSHOT_ID" --tags "$TAGS_JSON"
    
    if [ $? -eq 0 ]; then
      echo "Tags applied to snapshot $SNAPSHOT_ID: $TAGS_JSON"
    else
      echo "Failed to apply tags to snapshot $SNAPSHOT_ID"
    fi
  else
    echo "No tags found for volume $VOLUME_ID"
  fi

done < "$VOLUME_FILE"

echo "Snapshot IDs saved to $SNAPSHOT_OUTPUT_FILE"
