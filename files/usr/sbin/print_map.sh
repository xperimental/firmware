#!/bin/sh

#Print out local connection data for map creation

memory_usage()
{
	meminfo=$(cat /proc/meminfo)
	free=$(echo "$meminfo" | awk /^MemFree:/'{print($2)}')
	buffers=$(echo "$meminfo" | awk /^Buffers:/'{print($2)}')
	cached=$(echo "$meminfo" | awk /^Cached:/'{print($2)}')
	total=$(echo "$meminfo" | awk /^MemTotal:/'{print($2)}')
	echo $free $buffers $cached $total | awk '{ printf("%f", 1 - ($1 + $2 + $3) / $4)}'
}

rootfs_usage()
{
	df / | awk 'BEGIN {val=100} NR==2 {val=$5} END { printf("%.2f", val/100) }'
}

print_basic() {
	local community="$(uci -q get freifunk.@settings[0].community 2> /dev/null)"
	local version="$(uci -q get freifunk.@settings[0].version 2> /dev/null)"
	local name="$(uci -q get freifunk.@settings[0].name 2> /dev/null)"
	local longitude="$(uci -q get freifunk.@settings[0].longitude 2> /dev/null)"
	local latitude="$(uci -q get freifunk.@settings[0].latitude 2> /dev/null)"
	local contact="$(uci -q get freifunk.@settings[0].contact 2> /dev/null)"
	local autoupdater_enabled="$(uci -q get autoupdater.settings.enabled 2> /dev/null)"
	local autoupdater_branch="$(uci -q get autoupdater.settings.branch 2> /dev/null)"

	[ -n "$contact" ] && echo -n "\"contact\" : \"$contact\", "
	[ -n "$name" ] && echo -n "\"name\" : \"$name\", "
	[ -n "$version" ] && echo -n "\"firmware\" : \"ffbsee-$version\", "
	[ -n "$community" ] && echo -n "\"community\" : \"$community\", "

	if [ "$autoupdater_enabled" = "1" ]; then
		echo -n "\"autoupdater\" : \"$autoupdater_branch\", "
	fi

	if [ -n "$longitude" -a -n "$latitude" ]; then
		echo -n "\"longitude\" : $longitude, "
		echo -n "\"latitude\" : $latitude, "
	fi

	echo -n "\"model\" : \"$(cat /tmp/sysinfo/model)\", "
	echo -n "\"using_gateway\" : \"$(sockread /var/run/fastd.status < /dev/null 2> /dev/null | grep established | sed 's/\(.*\)"name": "\([^"]*\)"\(.*\)established\(.*\)/\2/g')\", "
	echo -n "\"links\" : ["

	printLink() { echo -n "{ \"smac\" : \"$(cat /sys/class/net/$3/address)\", \"dmac\" : \"$1\", \"qual\" : $2 }"; }
	IFS="
"
	nd=0
	for entry in $(batctl neighbors -H 2> /dev/null | awk -F '[][)( \t]+' '/^[a-f0-9]/{ print($1, $3, $4) }'); do
		[ $nd -eq 0 ] && nd=1 || echo -n ", "
		IFS=" "
		printLink $entry
	done

	echo -n '], '

	mac=$(uci -q get network.freifunk.macaddr)
	echo -n "$(batctl translocal -H 2> /dev/null | awk -v macs="$(cat /sys/class/net/*/address)" 'BEGIN{c=0} {if (index(macs, $1) == 0){ c+=1 }} END {printf("\"clientcount\" : %d", c)}')"
}

print_more() {
	echo -n "\"loadavg\" : $(uptime | awk '{print($NF)}'), "
	echo -n "\"uptime\" : $(awk '{print(int($1))}' /proc/uptime), "

	print_basic
}

print_all() {
	local prefix="$(uci -q get network.globals.ula_prefix)"
	echo -n "\"rootfs_usage\" : $(rootfs_usage), "
	echo -n "\"memory_usage\" : $(memory_usage), "
	echo -n "\"addresses\" : ["
	ip -6 address show dev br-freifunk 2> /dev/null | grep -v "$prefix" | tr '/' ' ' | awk 'BEGIN{i=0} /inet/ { if($2 !~ /^fe80/) { printf("%s\"%s\"", (i ? ", " : ""), $2); i=1; }}'
	echo -n "], "

	print_more
}

print() {
	echo -n "{"

	case $1 in
		"basic")
			print_basic
			;;
		"more")
			print_more
			;;
		"all")
			print_all
			;;
		*)
			;;
    esac

	echo -n '}'
}


map_level="$(uci -q get freifunk.@settings[0].publish_map 2> /dev/null)"

if [ "$1" = "-p" ]; then
	[ $map_level = "none" ] && exit 0

	content="$(print $map_level)"
	if [ -n "$content" ]; then
		#make sure alfred is running
		pidof alfred > /dev/null || /etc/init.d/alfred start

		#publish content via alfred
		echo "$content" | alfred -s 64
		echo "map published"
	else
		echo "nothing published"
	fi
else
	print $map_level
fi
