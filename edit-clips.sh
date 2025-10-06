#!/bin/bash

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
        split=$(jq -r ".exports[$i].clips[$j].split" data.json)

        if [ "$split" != "null" ] && [ -n "$split" ]; then
            # Handle split
            duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
            
            # Create first part of the split
            output_file_1="$VIDEO_EXPORT_DIR/${safe_title}_clip_$(($j + 1))_part_1.mp4"
            echo "Creating split part 1 (0 to $split) for $title"
            ffmpeg -y -i "$input_file" -ss 0 -to "$split" -c:v libx264 -c:a aac "$output_file_1" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Error creating split part 1 for $title"
            else
                echo "Successfully created: $output_file_1"
                created_files+=("$output_file_1")
            fi

            # Create second part of the split
            output_file_2="$VIDEO_EXPORT_DIR/${safe_title}_clip_$(($j + 1))_part_2.mp4"
            echo "Creating split part 2 ($split to end) for $title"
            ffmpeg -y -i "$input_file" -ss "$split" -to "$duration" -c:v libx264 -c:a aac "$output_file_2" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Error creating split part 2 for $title"
            else
                echo "Successfully created: $output_file_2"
                created_files+=("$output_file_2")
            fi
        elif [ "$start" != "null" ] && [ -n "$start" ] && [ "$end" != "null" ] && [ -n "$end" ]; then
            # Handle start/end clip
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
        else
            echo "Clip $j for $title has invalid or missing times, skipping..."
            continue
        fi
    done
done

echo "Clip extraction completed"
echo "Total clips created: ${#created_files[@]}"
