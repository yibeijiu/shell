#!/bin/bash
function collectinfo(){
host_name=$(cat /etc/hostname)
cpu=($(cat /proc/cpuinfo |grep 'model name'|cut -d':' -f 2 |uniq -c|awk  '{ for (i=2;i<=NF;i++) printf("%s ", $i);print ":"$1"core"}'))
MemTotal=$(cat /proc/meminfo |grep MemTotal|awk '{print $2$3}')
disk=($(export LANG="en_US.UTF_8" && fdisk -l|grep '^Disk /dev'|awk -F'[ ,]+' '{printf("%s%s%s",$2,$3,$4);print ";"}'))
echo "$ip,$host_name,${cpu[*]},$MemTotal,${disk[*]}"
}
host=$1
for i in `awk '{print $1}' $host`
do
	ssh root@$i  "$(declare -f collectinfo);declare -x ip=$i;collectinfo" >> info.csv &
#	sed -i "$ s/^/${i}\,/" info.csv
done
