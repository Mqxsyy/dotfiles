#!/bin/bash

DIR="/tmp/clip-recorder"

mkdir -p "$DIR"

INPUT="$DIR/rec.mp4"
COMPRESSED="$DIR/compressed.mp4"

ffmpeg -y -i "$INPUT" -c:v libx264 -crf 24 -preset slow "$COMPRESSED"

wl-copy -t text/uri-list <<<"file://$COMPRESSED"
