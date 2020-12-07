#!/bin/bash
set -e

FAN_PIN=17       # Which GPIO pin you're using to control the fan.
ON_THRESHOLD=65  # (degrees Celsius) Fan runs full speed at this temperature.
OFF_THRESHOLD=55 # (degress Celsius) Fan turns off at this temperature.

if [ $ON_THRESHOLD -le $OFF_THRESHOLD ]; then
	local tmp=$ON_THRESHOLD
	ON_THRESHOLD=$OFF_THRESHOLD
	OFF_THRESHOLD=$tmp
fi

ON=1
OFF=0
FAN="/sys/class/gpio/gpio$FAN_PIN"

# Ensure fan pin is enabled
if [ ! -d "$FAN" ]; then
	echo "$FAN_PIN" > '/sys/class/gpio/export'
fi

echo 'out' > "$FAN/direction"
echo "$OFF" > "$FAN/value"

while true; do
	temp=$(vcgencmd measure_temp | awk -F "[=']" '{print($2)}')

	if [ $temp -gt $ON_THRESHOLD ]; then

		if [ $(cat "$FAN/value") -eq $OFF ]; then
			echo $ON > "$FAN/value"
		fi

		interval=$(( $temp - $OFF_THRESHOLD + 1 ))

	elif [ $temp -lt $OFF_THRESHOLD ]; then

		if [ $(cat "$FAN/value") -eq $ON ]; then
			echo $OFF > "$FAN/value"
		fi

		interval=$(( ($ON_THRESHOLD - $temp) / 2 + 1 ))

	else
		if [ $(cat "$FAN/value") -eq $ON ]; then
			interval=$(( $temp - $OFF_THRESHOLD + 1 ))
		else
			interval=$(( ($ON_THRESHOLD - $temp) / 2 + 1 ))
		fi
	fi

	sleep $interval
done
