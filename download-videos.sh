#!/bin/zsh

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null; then
    echo "yt-dlp not installed"
    exit 1
fi

# Check if VIDEO_EXPORT_DIR environment variable is set
if [ -z "$VIDEO_EXPORT_DIR" ]; then
    echo "environment variable VIDEO_EXPORT_DIR must be set"
    exit 1
fi

# Check if VIDEO_EXPORT_DIR exists
if [ ! -d "$VIDEO_EXPORT_DIR" ]; then
    echo "VIDEO_EXPORT_DIR does not exist"
    exit 1
fi

# Read URLs from data.json and download videos
# Using jq to parse the JSON array
URLS=$(jq -r '.[]' data.json)

if [ $? -ne 0 ]; then
    echo "Error reading data.json"
    exit 1
fi

# Loop through each URL and download
while IFS= read -r url; do
    echo "Downloading: $url"
    yt-dlp -f "mp4" \
        -P "$VIDEO_EXPORT_DIR" \
        "$url"
done <<< "$URLS"

echo "All downloads completed"