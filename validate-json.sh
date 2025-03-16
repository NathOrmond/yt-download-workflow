#!/bin/zsh 

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it first."
    echo "sudo apt install jq  # Debian/Ubuntu"
    echo "brew install jq      # macOS"
    exit 1
fi

# Check if ajv-cli is installed
if ! command -v ajv &> /dev/null; then
    echo "Error: ajv-cli is not installed. Installing it now..."
    npm install -g ajv-cli ajv-formats
    if [ $? -ne 0 ]; then
        echo "Failed to install ajv-cli. Please install it manually:"
        echo "npm install -g ajv-cli ajv-formats"
        exit 1
    fi
fi

# Define file paths
schema_file="data.schema.json"
data_file="data.json"

# Check if files exist
if [ ! -f "$schema_file" ]; then
    echo "Error: Schema file $schema_file not found."
    exit 1
fi

if [ ! -f "$data_file" ]; then
    echo "Error: Data file $data_file not found."
    exit 1
fi

echo "Validating $data_file against $schema_file..."

# Basic validation using jq (simpler alternative if ajv-cli is not available)
jq -e 'has("exports") and (.exports | type) == "array"' "$data_file" > /dev/null
if [ $? -ne 0 ]; then
    echo "Basic validation failed: data.json must have an 'exports' array property."
    exit 1
fi

# Use ajv for full schema validation
ajv validate -s "$schema_file" -d "$data_file" --all-errors
validation_result=$?

if [ $validation_result -eq 0 ]; then
    echo "✅ Validation successful: $data_file is valid."
    
    # Additional timestamp validation
    echo "Checking timestamp formats..."
    exports_count=$(jq '.exports | length' "$data_file")
    valid_timestamps=true
    
    for i in $(seq 0 $(($exports_count - 1))); do
        clips_count=$(jq ".exports[$i].clips | length" "$data_file")
        
        for j in $(seq 0 $(($clips_count - 1))); do
            start=$(jq -r ".exports[$i].clips[$j].start" "$data_file")
            end=$(jq -r ".exports[$i].clips[$j].end" "$data_file")
            
            # Check if timestamps are in the correct format
            if [[ ! "$start" =~ ^([0-9]+:[0-5][0-9]:[0-5][0-9]|[0-9]+)$ ]]; then
                echo "Error: Invalid start timestamp format in export $i, clip $j: $start"
                valid_timestamps=false
            fi
            
            if [[ ! "$end" =~ ^([0-9]+:[0-5][0-9]:[0-5][0-9]|[0-9]+)$ ]]; then
                echo "Error: Invalid end timestamp format in export $i, clip $j: $end"
                valid_timestamps=false
            fi
            
            # Convert timestamps to seconds for comparison
            start_seconds=$(echo "$start" | awk -F: '{ if (NF==3) print ($1 * 3600) + ($2 * 60) + $3; else print $1 }')
            end_seconds=$(echo "$end" | awk -F: '{ if (NF==3) print ($1 * 3600) + ($2 * 60) + $3; else print $1 }')
            
            # Check if end is greater than start
            if (( start_seconds >= end_seconds )); then
                echo "Error: End time must be greater than start time in export $i, clip $j"
                valid_timestamps=false
            fi
        done
    done
    
    if [ "$valid_timestamps" = true ]; then
        echo "✅ All timestamps are valid."
        exit 0
    else
        echo "❌ Timestamp validation failed. Please check the errors above."
        exit 1
    fi
else
    echo "❌ Validation failed. Please check the errors above."
    exit 1
fi
