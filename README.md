
# YT Downloader Workflow

> This is a repo to speed up some stuff I do that involves downloading video from youtube for editing. It's a personal thing, but if it's useful for you let me know and if you wantme to build on this in anyway let me know (though most of the core functionality is part of the yt-dlp project)

- ## Prerequisites 

1. Make sure you have yt-dl installed [repo here](https://github.com/yt-dlp/yt-dlp) 

```zsh
  pip3 install yt-dlp
```

2. Make sure you have `jq` installed in your shell (for JSON parsing)

```zsh 
 sudo apt install jq
```

3. Make sure you have created a directory/folder to export your downloaded videos into: 

- set your download folder as an environment variable 
- > You can add this to your `.zshrc` if you want to avoid having to set this each terminal session
```zsh 
export VIDEO_EXPORT_DIR="/path/to/your/export/directory"
```

4.  Make sure your data.json file contains all the URL's you want to download
```
[
    "https://www.youtube.com/watch?v=example1",
    "https://www.youtube.com/watch?v=example2"
]
```

5.  make the .sh file executable
```zsh
chmod +x download_videos.sh
```

## To Run 

- Simply run the script 

```zsh 
./download_videos.sh
```


## To Edit Clips 

- use the `edit-clips.sh` file 

- Add timestamps for the clips you want to edit
```zsh
declare -a segments=(
    "ss ss"
)
```

- Run script against video file
```zsh
./edit-clis.sh $VIDEO_EXPORT_DIR/my_file.mp4
```

