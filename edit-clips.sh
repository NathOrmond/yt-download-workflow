#!/bin/zsh

# Check if input file was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 input_file.mp4"
    exit 1
fi

# Get input file path and name
input_file="$1"
filename=$(basename -- "$input_file")
output_file="${VIDEO_EXPORT_DIR}/${filename%.*}_edited.mp4"

# Add start and end times for each segment
# here (in seconds) 
declare -a segments=(
    #"ss ss"
)

# Build the filter complex string
filter_complex=""
video_concat=""
audio_concat=""

for i in "${!segments[@]}"; do
    n=$((i+1))
    read start end <<< "${segments[i]}"
    # Add trim commands
    filter_complex+="[0:v]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v$n];"
    filter_complex+="[0:a]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a$n];"
    # Build concat lists
    video_concat+="[v$n]"
    audio_concat+="[a$n]"
done

# Add concat commands
filter_complex+="$video_concat concat=n=${#segments[@]}[outv];"
filter_complex+="$audio_concat concat=n=${#segments[@]}:v=0:a=1[outa]"

ffmpeg -i "$input_file" -filter_complex "$filter_complex" \
    -map "[outv]" -map "[outa]" "$output_file"
