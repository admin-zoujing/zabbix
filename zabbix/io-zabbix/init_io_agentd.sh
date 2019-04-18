#!/bin/bash

#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/io-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm
#zabbix server的ip地址，多个ip使用逗号分隔
sed -i 's|Server=127.0.0.1|Server=192.168.30.100| ' /etc/zabbix/zabbix_agentd.conf
sed -i 's|ServerActive=127.0.0.1|ServerActive=192.168.30.100| ' /etc/zabbix/zabbix_agentd.conf
#zabbix agent的ip地址
sed -i 's|Hostname=Zabbix server|Hostname=192.168.30.71| ' /etc/zabbix/zabbix_agentd.conf


#2、配置zabbix-agent监听shell脚本（需要修改主机客户端地址）
mkdir -pv /etc/zabbix/externalscripts
echo '#!/bin/bash
dev=$1
type=$2
#enable debug mode
debug=0

if [[ -z "$dev" ]]; then
  echo "error: wrong input value (device)"
  exit 1
fi

if [[ -z "$type" ]]; then
  echo "error: wrong input value (type)"
  exit 1
fi

columns=`iostat -xN |egrep -o "^Device.*"`

columnsarray=($columns)

column_id=1

for i in "${columnsarray[@]}"
do
        #echo "column: $i"

        if [[ "$i" = "$type" ]]; then

            if [[ $debug -eq 1 ]]; then
                echo "right column (${i}) found...column_id: $column_id "
            fi

            id="$"
            column_id_id=$id$column_id

            iostats=`iostat -xN |egrep -o "^${dev}[[:space:]]+.*" |awk "{print ${column_id_id}}"`
        fi
    column_id=$[column_id + 1]
done

if [ -z "$iostats" ]; then
    echo "error: \"device\" or \"type\" not found (${dev},${type})"
    exit 3
fi

iostats_lines=`wc -l <<< "$iostats"`

if [ $iostats_lines -ne 1 ]; then
    echo "error: wrong output value (${iostats_lines})"
    exit 2
fi

echo $iostats

if [[ $debug -eq 1 ]]; then
    echo "- - - - - - - - - -"
    echo $columns
    iostats_debug=`iostat -xN |egrep -o "^${dev}[[:space:]]+.*"`
    echo $iostats_debug
    echo "- - - - - - - - - -"
fi

exit 0
' > /etc/zabbix/externalscripts/zbx_parse_iostat_values.sh


echo '#!/usr/bin/perl

# G. Husson - Thalos - 20120713
# Zabbix 2 - disk autodiscovery for linux
# all disks listed in /proc/diskstats are returned
# special processing on LVMs
# special processing on Proxmox VE disks (VM id and VM name are returned)
# rq : in Zabbix, create a regexp filter on which disks you want to monitor on your IT System
# ex : ^(hd[a-z]+|sd[a-z]+|vd[a-z]+|dm-[0-9]+|drbd[0-9]+)$
#      ^(loop[0-9]+|sr[0-9]*|fd[0-9]*)$

# Custom keys :
#UserParameter=custom.vfs.dev.read.ops[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$4}"
#UserParameter=custom.vfs.dev.read.ms[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$7}"
#UserParameter=custom.vfs.dev.write.ops[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$8}"
#UserParameter=custom.vfs.dev.write.ms[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$11}"
#UserParameter=custom.vfs.dev.io.active[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$12}"
#UserParameter=custom.vfs.dev.io.ms[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$13}"
#UserParameter=custom.vfs.dev.read.sectors[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$6}"
#UserParameter=custom.vfs.dev.write.sectors[*],cat /proc/diskstats | grep "$1" | head -1 | awk "{print $$10}"

# Discovery items creation :
#Disk {#VMNAME}:{#DMNAME} io spent      custom.vfs.dev.io.ms[{#DISK}]
#Disk {#VMNAME}:{#DMNAME} read bw       custom.vfs.dev.read.sectors[{#DISK}]
#Disk {#VMNAME}:{#DMNAME} read io       custom.vfs.dev.read.ops[{#DEV}]
#Disk {#VMNAME}:{#DMNAME} write bw      custom.vfs.dev.write.sectors[{#DISK}]
#Disk {#VMNAME}:{#DMNAME} write io      custom.vfs.dev.write.ops[{#DEV}]

# give disk dmname, returns Proxmox VM name
sub get_vmname_by_id
  {
  $vmname=`cat /etc/qemu-server/$_[0].conf | grep name | cut -d \: -f 2`;
  $vmname =~ s/^\s+//; #remove leading spaces
  $vmname =~ s/\s+$//; #remove trailing spaces
  return $vmname
  }

$first = 1;
print "{\n";
print "\t\"data\":[\n\n";

for (`cat /proc/diskstats`)
  {
  ($major,$minor,$disk) = m/^\s*([0-9]+)\s+([0-9]+)\s+(\S+)\s.*$/;
  $dmnamefile = "/sys/dev/block/$major:$minor/dm/name";
  $vmid= "";
  $vmname = "";
  $dmname = $disk;
  $diskdev = "/dev/$disk";
  # DM name
  if (-e $dmnamefile) {
    $dmname = `cat $dmnamefile`;
    $dmname =~ s/\n$//; #remove trailing \n
    $diskdev = "/dev/mapper/$dmname";
    # VM name and ID
    if ($dmname =~ m/^.*--([0-9]+)--.*$/) {
      $vmid = $1;
      #$vmname = get_vmname_by_id($vmid);
      }
    }
  #print("$major $minor $disk $diskdev $dmname $vmid $vmname \n");

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#DISK}\":\"$disk\",\n";
  print "\t\t\"{#DISKDEV}\":\"$diskdev\",\n";
  print "\t\t\"{#DMNAME}\":\"$dmname\",\n";
  print "\t\t\"{#VMNAME}\":\"$vmname\",\n";
  print "\t\t\"{#VMID}\":\"$vmid\"\n";
  print "\t}\n";
  }

print "\n\t]\n";
print "}\n";
' > /etc/zabbix/externalscripts/discover_disk.pl


#3、配置zabbix-agent监听（需要修改允许监听的服务器地址）
echo 'LogFile=/var/log/zabbix/zabbix_agentd_io.log
ListenPort=10050
HostMetadataItem=system.uname

UserParameter=discovery.disks.iostats,/etc/zabbix/externalscripts/discover_disk.pl
UserParameter=custom.vfs.dev.iostats.rrqm[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "rrqm/s"
UserParameter=custom.vfs.dev.iostats.wrqm[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "wrqm/s"
UserParameter=custom.vfs.dev.iostats.rps[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "r/s"
UserParameter=custom.vfs.dev.iostats.wps[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "w/s"
UserParameter=custom.vfs.dev.iostats.rsec[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "rsec/s"
UserParameter=custom.vfs.dev.iostats.wsec[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "wsec/s"
UserParameter=custom.vfs.dev.iostats.avgrq[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "avgrq-sz"
UserParameter=custom.vfs.dev.iostats.avgqu[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "avgqu-sz"
UserParameter=custom.vfs.dev.iostats.await[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "await"
UserParameter=custom.vfs.dev.iostats.svctm[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "svctm"
UserParameter=custom.vfs.dev.iostats.util[*],/etc/zabbix/externalscripts/zbx_parse_iostat_values.sh $1 "%util"
' > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_io.conf

#4、启动nzabbix-agent服务
chmod -R 755 /etc/zabbix
systemctl enable zabbix-agent
systemctl restart zabbix-agent
firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent;
firewall-cmd --permanent --query-port=10050/tcp;
firewall-cmd --reload;
