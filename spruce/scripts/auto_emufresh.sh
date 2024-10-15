#!/bin/sh

EMU_DIR="/mnt/SDCARD/Emu"
SPRUCE_DIR="/mnt/SDCARD/Saves/spruce"
LAST_LS_FILE="$SPRUCE_DIR/emufresh.ls"
CURRENT_LS="$(ls -R $EMU_DIR)"
EMUFRESH="$/mnt/SDCARD/spruce/scripts/emufresh_new.sh"

if [ -f "$LAST_LS_FILE" ]; then
	LAST_LS="$(cat "$LAST_LS_FILE")"
	if [ "$LAST_LS" != "$CURRENT_LS" ]; then
		"$EMU_FRESH"
	fi
fi
echo "$CURRENT_LS" > "$LAST_LS_FILE"
