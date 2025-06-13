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
    exit 0
else
    echo "❌ Validation failed. Please check the errors above."
    exit 1
fi
