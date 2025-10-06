#!/bin/bash
# Create output directory if VIDEO_EXPORT_DIR is not set
if [ -z "$VIDEO_EXPORT_DIR" ]; then
    echo "VIDEO_EXPORT_DIR not set. Would you like to specify an export directory? (y/n)"
    read response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Please enter the path for your export directory:"
        read custom_dir
        
        if [ ! -d "$custom_dir" ]; then
            echo "Directory '$custom_dir' does not exist. Would you like to create it? (y/n)"
            read create_dir
            
            if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                mkdir -p "$custom_dir"
                if [ $? -ne 0 ]; then
                    echo "Failed to create directory. Using default instead."
                    custom_dir="./output"
                    mkdir -p "$custom_dir"
                fi
            else
                echo "Using default output directory instead."
                custom_dir="./output"
                mkdir -p "$custom_dir"
            fi
        fi
        
        export VIDEO_EXPORT_DIR="$custom_dir"
    else
        echo "Using default output directory './output'"
        mkdir -p "./output"
        export VIDEO_EXPORT_DIR="./output"
    fi
fi

echo "Videos will be exported to: $VIDEO_EXPORT_DIR"

# Run the download process
echo "Starting download process..."
./download-videos.sh

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Error during download process. Exiting."
    exit 1
fi

# Run the edit process
echo "Starting edit process..."
./edit-clips.sh

# Show summary of created files
echo "Process complete. Files created:"
find "$VIDEO_EXPORT_DIR" -type f -newer ".workflow_timestamp" | sort

# Create a timestamp file for the next run
touch .workflow_timestamp