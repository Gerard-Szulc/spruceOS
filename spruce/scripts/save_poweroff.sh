#!/bin/sh
. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

BIN_PATH="/mnt/SDCARD/spruce/bin"
FLAGS_DIR="/mnt/SDCARD/spruce/flags"

kill_current_process() {
	pid=$(ps | grep cmd_to_run | grep -v grep | sed 's/[ ]\+/ /g' | cut -d' ' -f2)
	ppid=$pid
	while [ "" != "$pid" ]; do
		ppid=$pid
		pid=$(pgrep -P $ppid)
	done

	if [ "" != "$ppid" ]; then
		kill -9 $ppid
	fi
}

vibrate

# Save system brightness level
# this is done first because the brightness may be modify later - oscar
cat /sys/devices/virtual/disp/disp/attr/lcdbl > /mnt/SDCARD/spruce/settings/sys_brightness_level

if pgrep -f gameswitcher.sh > /dev/null ; then
	# pause game switcher
	killall -q -19 switcher
	# remove lastgame flag to prevent loading any App after next boot
    flag_remove "lastgame"
	# add flag to load game switcher after next boot
	flag_add "gs"
	# display shutdown warning
	display -t "Shutting down..." -i "/mnt/SDCARD/spruce/imgs/bg_tree.png"
	dim_screen &
fi

# ask for user response if MainUI or PICO8 is running and skip_shutdown_confirm setting is not set
if flag_check "in_menu" || pgrep "pico8_dyn" >/dev/null; then
	if ! setting_get "skip_shutdown_confirm"; then
		messages_file="/var/log/messages"
		# pause MainUI or pico8_dyn
		killall -q -19 MainUI
		killall -q -19 pico8_dyn
		# show notification screen
		display --text "Are you sure you want to shutdown?" --image "/mnt/SDCARD/spruce/imgs/bg_tree.png" --confirm
		if confirm 30 0; then
			# remove lastgame flag to prevent loading any App after next boot
			rm "${FLAGS_DIR}/lastgame.lock"
			# display shutdown warning
			display -t "Shutting down..." -i "/mnt/SDCARD/spruce/imgs/bg_tree.png"
			dim_screen &
		else
			display_kill
			# resume Mainui or pico8_dyn
			killall -q -18 MainUI
			killall -q -18 pico8_dyn
			# exit script
			return 0
		fi
	else
		# If skip_shutdown_confirm setting is set or not in menu, proceed with shutdown
		rm "${FLAGS_DIR}/lastgame.lock"
		# display shutdown warning
		display -t "Shutting down..." -i "/mnt/SDCARD/spruce/imgs/bg_tree.png"
		dim_screen &
	fi
fi

# notify user with led
echo heartbeat >/sys/devices/platform/sunxi-led/leds/led1/trigger

# kill principle and runtime first so no new app / MainUI will be loaded anymore
killall -q -15 runtime.sh
killall -q -15 principal.sh

# kill enforceSmartCPU first so no CPU setting is changed during shutdown
killall -q -15 enforceSmartCPU.sh

# kill app if not emulator is running
if cat /tmp/cmd_to_run.sh | grep -q -v '/mnt/SDCARD/Emu'; then
	kill_current_process
	# remove lastgame flag to prevent loading any App after next boot
	rm "${FLAGS_DIR}/lastgame.lock"
fi

# kill PICO8 if PICO8 is running
if pgrep "pico8_dyn" >/dev/null; then
	killall -q -15 pico8_dyn
fi

# trigger auto save and send kill signal
if pgrep "ra32.miyoo" >/dev/null; then
	# {
	#     echo 1 1 0   # MENU up
	#     echo 1 57 1  # A down
	#     echo 1 57 0  # A up
	#     echo 0 0 0   # tell sendevent to exit
	# } | $BIN_PATH/sendevent /dev/input/event3
	# sleep 0.3
	killall -q -15 ra32.miyoo
elif pgrep "PPSSPPSDL" >/dev/null; then
	{
		echo 1 314 1 # SELECT down
		echo 3 2 255 # L2 down
		echo 3 2 0   # L2 up
		echo 1 314 0 # SELECT up
		echo 0 0 0   # tell sendevent to exit
	} | $BIN_PATH/sendevent /dev/input/event4
	sleep 1
	killall -q -15 PPSSPPSDL
else
	killall -q -15 retroarch
	killall -q -15 drastic
	killall -q -9 MainUI
fi

# wait until emulator or MainUI exit
while killall -q -0 ra32.miyoo ||
	killall -q -0 retroarch ||
	killall -q -0 PPSSPPSDL ||
	killall -q -0 drastic ||
	killall -q -0 MainUI; do
	sleep 0.5
done

# show saving screen
if ! pgrep "display_text.elf" >/dev/null; then
	display --icon "/mnt/SDCARD/spruce/imgs/save.png" -t "Saving and shutting down... Please wait a moment."
	dim_screen &
fi

# Created save_active flag
if flag_check "in_menu"; then
    flag_remove "save_active"
else
    flag_add "save_active"
fi

if flag_check "syncthing" && flag_check "emulator_launched"; then
	log_message "Syncthing is enabled, WiFi connection needed"

	if check_and_connect_wifi; then
		# Dimming screen before syncthing sync check
		dim_screen &
		/mnt/SDCARD/spruce/bin/Syncthing/syncthing_sync_check.sh --shutdown
	fi

	flag_remove "syncthing_startup_synced"
fi

flag_remove "emulator_launched"

# Saved current sound settings
alsactl store

# All processes should have been killed, safe to update time if enabled
/mnt/SDCARD/spruce/scripts/geoip_timesync.sh

# Now that nothing might need it, organize settings file
settings_organize

# sync files and power off device
sync
poweroff
