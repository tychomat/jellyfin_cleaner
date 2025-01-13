#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found."
    exit 1
fi

# Check if required variables are set
if [ -z "$JELLYFIN_SERVER" ] || [ -z "$API_TOKEN" ] || [ -z "$USER_ID" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Variables
SHOW_NAME="last week"  # Replace with the show name you want to search
ENCODED_SHOW_NAME=$(echo "$SHOW_NAME" | sed 's/ /%20/g')  # URL encode the show name

# Step 1: Search for the TV show
SHOW_SEARCH_URL="$JELLYFIN_SERVER/Items?searchTerm=$ENCODED_SHOW_NAME&includeItemTypes=Series&Recursive=true"
SHOW_ID=$(curl -s -X GET "$SHOW_SEARCH_URL" -H "X-Emby-Token: $API_TOKEN" | jq -r '.Items[0].Id')

# Check if a valid show ID was found
if [ -z "$SHOW_ID" ]; then
    echo "Error: TV show '$SHOW_NAME' not found."
    exit 1
fi

echo "TV show '$SHOW_NAME' found with ID: $SHOW_ID"

# Step 2: Retrieve watched episodes from the show
WATCHED_EPISODES_URL="$JELLYFIN_SERVER/Users/$USER_ID/Items?ParentId=$SHOW_ID&includeItemTypes=Episode&IsPlayed=true&Recursive=true"
WATCHED_EPISODES=$(curl -s -X GET "$WATCHED_EPISODES_URL" -H "X-Emby-Token: $API_TOKEN" | jq -r '.Items[].Id')

if [ -z "$WATCHED_EPISODES" ]; then
    echo "No watched episodes found for '$SHOW_NAME'."
    exit 0
fi

echo "Watched episodes found for '$SHOW_NAME'. Proceeding to delete them."

# Step 3: Delete each watched episode
for EPISODE_ID in $WATCHED_EPISODES; do
    DELETE_URL="$JELLYFIN_SERVER/Items/$EPISODE_ID?api_key=$API_TOKEN"
    echo "Deleting episode with ID: $EPISODE_ID"
    curl -s -X DELETE "$DELETE_URL"
done

echo "All watched episodes of '$SHOW_NAME' have been deleted."
