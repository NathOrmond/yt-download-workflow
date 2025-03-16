heck if yt-dlp is installed
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

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq not installed"
    exit 1
fi

# Read data from data.json
if [ ! -f "data.json" ]; then
    echo "data.json file not found"
    exit 1
fi

# Validate JSON structure
jq -e '.exports' data.json > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Invalid data.json format. Expected structure with 'exports' array."
    exit 1
fi

# Process each export item
export_count=$(jq '.exports | length' data.json)
echo "Found $export_count export items to process"

for i in $(seq 0 $(($export_count - 1))); do
    title=$(jq -r ".exports[$i].title" data.json)
    url=$(jq -r ".exports[$i].url" data.json)
    
    if [ -z "$title" ] || [ "$title" = "null" ]; then
        echo "Export item $i is missing a title, skipping..."
        continue
    fi
    
    if [ -z "$url" ] || [ "$url" = "null" ]; then
        echo "Export item $i is missing a URL, skipping..."
        continue
    fi
    
    echo "Downloading: $title ($url)"
    
    # Use title as the output filename
    # Replace spaces with underscores and remove special characters
    safe_title=$(echo "$title" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    
    yt-dlp -f "mp4" \
        -o "$VIDEO_EXPORT_DIR/$safe_title.%(ext)s" \
        "$url"
    
    if [ $? -ne 0 ]; then
        echo "Error downloading $title"
    else
        echo "Successfully downloaded $title"
    fi
done

echo "All downloads completed"
