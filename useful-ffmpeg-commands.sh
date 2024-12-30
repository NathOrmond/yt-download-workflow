#!/bin/zsh

# Add start and ent times for each segment
# here (in seconds) 
declare -a segments=(
    # "30 60"    # segment 1
    # "120 150"  # segment 2
    # "180 210"  # segment 3
    # "240 270"  # segment 4
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

ffmpeg -i input.mp4 -filter_complex "$filter_complex" \
    -map "[outv]" -map "[outa]" output.mp4