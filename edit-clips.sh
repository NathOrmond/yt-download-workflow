heck if VIDEO_EXPORT_DIR environment variable is set
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

# Process each export item
export_count=$(jq '.exports | length' data.json)
echo "Processing $export_count videos for clip extraction"

# Create a file to track created clips
created_files=()

for i in $(seq 0 $(($export_count - 1))); do
    title=$(jq -r ".exports[$i].title" data.json)
    clips_count=$(jq ".exports[$i].clips | length" data.json)
    
    if [ -z "$title" ] || [ "$title" = "null" ]; then
        echo "Export item $i is missing a title, skipping..."
        continue
    fi
    
    if [ "$clips_count" -eq 0 ]; then
        echo "No clips defined for $title, skipping..."
        continue
    fi
    
    # Sanitize title for filename
    safe_title=$(echo "$title" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    input_file="$VIDEO_EXPORT_DIR/$safe_title.mp4"
    
    if [ ! -f "$input_file" ]; then
        echo "Input file not found: $input_file"
        continue
    fi
    
    echo "Processing $clips_count clips for $title"
    
    # Process each clip
    for j in $(seq 0 $(($clips_count - 1))); do
        start=$(jq -r ".exports[$i].clips[$j].start" data.json)
        end=$(jq -r ".exports[$i].clips[$j].end" data.json)
        
        if [ -z "$start" ] || [ "$start" = "null" ] || [ -z "$end" ] || [ "$end" = "null" ]; then
            echo "Clip $j for $title has invalid start/end times, skipping..."
            continue
        fi
        
        clip_num=$((j + 1))
        output_file="$VIDEO_EXPORT_DIR/${safe_title}_clip_${clip_num}.mp4"
        
        echo "Extracting clip $clip_num ($start to $end) from $title"
        
        ffmpeg -y -i "$input_file" -ss "$start" -to "$end" \
            -c:v libx264 -c:a aac "$output_file" >/dev/null 2>&1
        
        if [ $? -ne 0 ]; then
            echo "Error creating clip $clip_num for $title"
        else
            echo "Successfully created: $output_file"
            created_files+=("$output_file")
        fi
    done
done

echo "Clip extraction completed"
echo "Total clips created: ${#created_files[@]}"
