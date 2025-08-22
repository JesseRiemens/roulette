#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Run flutter with the API key as a define
flutter run --dart-define=HASTEBIN_API_KEY="$HASTEBIN_API_KEY" "$@"