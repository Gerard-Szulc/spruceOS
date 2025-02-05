#!/bin/sh

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh
BG="/mnt/SDCARD/spruce/imgs/bg_tree.png"
EMU_NAME="$(echo "$1" | cut -d'/' -f5)"
CONFIG="/mnt/SDCARD/Emu/${EMU_NAME}/config.json"
SYS_OPT="/mnt/SDCARD/Emu/.emu_setup/options/${EMU_NAME}.opt"

display -i "$BG" -t "Core changed to quicknes"

sed -i 's|"Emu Core: fceumm-(✓NESTOPIA)-quicknes"|"Emu Core: fceumm-nestopia-(✓QUICKNES)"|g' "$CONFIG"
sed -i 's|"/mnt/SDCARD/Emu/.emu_setup/core/quicknes.sh"|"/mnt/SDCARD/Emu/.emu_setup/core/fceumm.sh"|g' "$CONFIG"
sed -i 's|CORE=.*|CORE=\"quicknes\"|g' "$SYS_OPT"

sleep 2
display_kill
