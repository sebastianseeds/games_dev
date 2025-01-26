#!/bin/bash

# Path to game folder
GAME_DIR="/Users/sebastianseeds/games_dev/explore-simple"

# Arb. port for the HTTP server
PORT=8080

# Start the server and open the game in the default browser
cd "$GAME_DIR" || exit 1
http-server -p "$PORT" & # Start the server in the background
sleep 2 # Give the server a moment to start

# Open the game in the default browser
#open "http://localhost:$PORT"

/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --auto-open-devtools-for-tabs "http://localhost:$PORT"

# Wait for the user to stop the server
echo "Press Ctrl+C to stop the server and exit."
wait
