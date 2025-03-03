#!/bin/bash
# Prevent suspend if Plex server is currently streaming

# Plex token (obtain from your Plex account):
PLEX_TOKEN=""
# URL to query Plex sessions
PLEX_URL="http://localhost:32400/status/sessions?X-Plex-Token=${PLEX_TOKEN}"
# Prevent sleep for 1800 seconds(30 min).
SLEEP_DURATION=1800

# Get Plex sessions in JSON format
response=$(curl -s -H "Accept: application/json" "$PLEX_URL")
# Extract the "size" field which indicates the number of active sessions
active_sessions=$(echo "$response" | jq '.MediaContainer.size')

# Check if there is at least one active session
if [ "$active_sessions" -gt 0 ]; then
    logger -t plex_inhibit "Active Plex stream detected ($active_sessions session(s)). Preventing suspend for $SLEEP_DURATION seconds."
    # Prevent idle suspend by holding an inhibitor lock for the specified duration
    systemd-inhibit --what=idle --who="Plex Monitor" --why="Active Plex streaming" sleep "$SLEEP_DURATION"
else
    logger -t plex_inhibit "No active Plex streams detected."
fi
