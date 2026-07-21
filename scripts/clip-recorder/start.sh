#!/bin/bash

REC_GIF=false

DIR="/tmp/clip-recorder"

mkdir -p "$DIR"

INPUT="$DIR/rec.mp4"
OUTPUT="$DIR/rec.avif"

rm -f "$INPUT"

wf-recorder -r 30 -g "$(slurp)" -f "$INPUT" -c libx264 -p crf=22

[ ! -f "$INPUT" ] && exit 1

if $REC_GIF; then
	ffmpeg -y -i "$INPUT" -c:v libsvtav1 -crf 30 -preset 6 "$OUTPUT"
	wl-copy -t text/uri-list <<<"file://$OUTPUT"
else
	wl-copy -t text/uri-list <<<"file://$INPUT"
fi
