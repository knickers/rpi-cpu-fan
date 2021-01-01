#!/bin/bash
set -e

# Which GPIO pin you're using to control the fan.
if [ -n "$1" ]; then
	FAN_PIN="$1"
else
	FAN_PIN=14
fi

# (degrees Celsius) Fan runs full speed at this temperature.
if [ -n "$2" ]; then
	ON_THRESHOLD="$2"
else
	ON_THRESHOLD=65
fi

# (degress Celsius) Fan turns off at this temperature.
if [ -n "$3" ]; then
	OFF_THRESHOLD="$3"
else
	OFF_THRESHOLD=$(( $ON_THRESHOLD - 10 ))
fi

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

while true; do
	temp=$(vcgencmd measure_temp | awk -F "[=']" '{print($2)}' | xargs printf '%.0f')

	if [ $temp -ge $ON_THRESHOLD ]; then

		if [ $(cat "$FAN/value") -eq $OFF ]; then
			echo $ON > "$FAN/value"
		fi

		interval=$(( $temp - $OFF_THRESHOLD + 1 ))

	elif [ $temp -le $OFF_THRESHOLD ]; then

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
