#!/bin/sh

echo "{==DBG==} INIT SCRIPT"

mount -t proc none /proc
mount -t sysfs none /sys

# echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"
echo -e "{==DBG==} Boot took $(cut -d' ' -f1 /proc/uptime) seconds"

exec /bin/sh
