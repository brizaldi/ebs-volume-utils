#!/bin/bash

# File containing the list of snapshot IDs
SNAPSHOT_FILE=$1

# Check if file is provided
if [ -z "$SNAPSHOT_FILE" ]; then
  echo "Usage: $0 <snapshot_ids_file>"
  exit 1
fi

# Check if file exists
if [ ! -f "$SNAPSHOT_FILE" ]; then
  echo "File $SNAPSHOT_FILE not found!"
  exit 1
fi

# Iterate through each snapshot ID in the file
while IFS= read -r SNAPSHOT_ID; do
  if [ -z "$SNAPSHOT_ID" ]; then
    continue  # Skip empty lines
  fi

  echo "Archiving snapshot: $SNAPSHOT_ID"

  # Archive the snapshot by changing its storage tier to 'archive'
  aws ec2 modify-snapshot-tier --snapshot-id "$SNAPSHOT_ID" --storage-tier archive
  
  if [ $? -eq 0 ]; then
    echo "Snapshot $SNAPSHOT_ID successfully archived."
  else
    echo "Failed to archive snapshot $SNAPSHOT_ID"
  fi

done < "$SNAPSHOT_FILE"

echo "Archiving process completed."
