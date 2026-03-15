#!/bin/bash

echo "School Management Flutter App"
echo "=============================="
echo ""

# Check if Supabase is running
echo "Checking Supabase status..."
if ! supabase status > /dev/null 2>&1; then
    echo "Supabase is not running. Starting now..."
    supabase start --workdir . || {
        echo "Failed to start Supabase"
        exit 1
    }
fi

echo "Supabase is running"
echo "  Studio: http://127.0.0.1:54323"
echo "  Mailpit: http://127.0.0.1:54324"
echo ""

# Start Edge Functions in background
echo "Starting Supabase Edge Functions..."
supabase functions serve --workdir . &
FUNCTIONS_PID=$!
echo "  Edge Functions PID: $FUNCTIONS_PID"
echo ""

# Kill any existing flutter process on port 3000
lsof -ti :3000 | xargs kill -9 2>/dev/null

# Create named pipe for flutter stdin
PIPE=/tmp/flutter_stdin_$$
mkfifo "$PIPE"

# Cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down..."
    kill "$FLUTTER_PID" 2>/dev/null
    kill "$WATCHER_PID" 2>/dev/null
    kill "$FUNCTIONS_PID" 2>/dev/null
    rm -f "$PIPE"
    exit 0
}
trap cleanup INT TERM EXIT

echo "Starting Flutter on http://localhost:3000"
echo "Auto-reload enabled — saves to lib/**/*.dart will trigger hot reload"
echo "Press Ctrl+C to stop"
echo ""

# Keep pipe open and run flutter
( flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0 < "$PIPE" ) &
FLUTTER_PID=$!

# Open the pipe for writing (keeps it open so flutter doesn't see EOF)
exec 3>"$PIPE"

# Watch lib/ for dart file changes and send hot reload
fswatch -o --event Updated --event Created lib/ | while read; do
    echo "  [hot reload] dart file changed"
    echo "r" >&3
done &
WATCHER_PID=$!

wait "$FLUTTER_PID"
