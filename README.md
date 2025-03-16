# YT Downloader Workflow

> This is a repo to speed up some stuff I do that involves downloading video from YouTube for editing. It's a personal thing, but if it's useful for you let me know and if you want me to build on this in any way let me know (though most of the core functionality is part of the yt-dlp project)

## Prerequisites 

1. Make sure you have yt-dlp installed [repo here](https://github.com/yt-dlp/yt-dlp) 
```zsh
pip3 install yt-dlp
```

2. Make sure you have `jq` installed in your shell (for JSON parsing)
```zsh 
sudo apt install jq
```

3. Make sure you have `ffmpeg` installed for video processing
```zsh
sudo apt install ffmpeg
```

4. For JSON schema validation, you'll need ajv-cli (optional)
```zsh
npm install -g ajv-cli ajv-formats
```

5. Make sure all scripts are executable
```zsh
chmod +x yt-workflow.sh download-videos.sh edit-clips.sh validate-json.sh
```

5. Configure your videos and clips in the `data.json` file (see below for schema)

## Environment Variable Handling

There are two ways to specify where your videos will be exported:

1. Set an environment variable before running:
```zsh 
export VIDEO_EXPORT_DIR="/path/to/your/export/directory"
```
> You can add this to your `.zshrc` if you want to avoid having to set this each terminal session

2. Let the script handle it automatically:
   - If `VIDEO_EXPORT_DIR` is not set, the script will ask if you want to specify a directory
   - You can either provide a custom path or use the default `./output` directory
   - The script will create the directory if needed

## data.json Schema

The `data.json` file now uses a more detailed structure to specify videos and clips:

```json
{
  "exports": [
    {
      "title": "Video Title",
      "url": "https://youtu.be/example",
      "clips": [
        {
          "start": "00:01:15",
          "end": "00:02:30"
        },
        {
          "start": "00:05:45",
          "end": "00:07:20"
        }
      ]
    }
  ]
}
```

- `title`: Used as the filename for the downloaded video and clips
- `url`: YouTube video URL
- `clips`: Array of clip segments to extract
  - `start`: Starting timestamp (HH:MM:SS or seconds)
  - `end`: Ending timestamp (HH:MM:SS or seconds)

### Timestamp Format

The tool supports two timestamp formats:
1. HH:MM:SS format (e.g., "01:23:45" for 1 hour, 23 minutes, 45 seconds)
2. Seconds as a number (e.g., "3661" for 1 hour, 1 minute, 1 second)

For HH:MM:SS format:
- Hours can be any number (0+)
- Minutes must be 00-59
- Seconds must be 00-59

> **Note:** To specify a clip from a specific time to the end of the video, just use the end timestamp of the video.

Each clip will be output as `{title}_clip_{number}.mp4` where `number` starts from 1.

### Validating Your JSON

You can validate your data.json file against the schema using the included script:

```zsh
./validate-json.sh
```

This will check that your configuration is correctly formatted and that all timestamps are valid.

## Running the Workflow

The simplest way to run the entire workflow is:

```zsh 
./yt-workflow.sh
```

This will:
1. Check/prompt for the export directory
2. Download all videos specified in data.json
3. Extract all clips based on the timestamps
4. Display a list of all created files

## Running Individual Steps

You can still run the individual scripts if needed:

```zsh
# Just download the videos
./download-videos.sh

# Just extract clips from already downloaded videos
./edit-clips.sh
```

Note that both scripts require the `VIDEO_EXPORT_DIR` to be set, either manually or through the main workflow script.

## Output

After running the workflow, you'll get:
- One MP4 file per video entry in data.json
- One MP4 clip file for each clip entry under each video
- A summary of all created files displayed in the terminal
