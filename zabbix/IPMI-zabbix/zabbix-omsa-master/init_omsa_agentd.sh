#!/bin/bash

#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/IPMI-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm
#zabbix server的ip地址，多个ip使用逗号分隔
sed -i 's|Server=127.0.0.1|Server=192.168.30.100| ' /etc/zabbix/zabbix_agentd.conf
sed -i 's|ServerActive=127.0.0.1|ServerActive=192.168.30.71| ' /etc/zabbix/zabbix_agentd.conf
#zabbix agent的ip地址
sed -i 's|Hostname=Zabbix server|Hostname=192.168.30.71| ' /etc/zabbix/zabbix_agentd.conf

sed -i 's|# UnsafeUserParameters=0|UnsafeUserParameters=1| ' /etc/zabbix/zabbix_agentd.conf
#sed -i 's|# Timeout=3|Timeout=30| ' /etc/zabbix/zabbix_agentd.conf

#2、配置zabbix-agent监听（需要修改允许监听的服务器地址）
echo '
' > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_Hareware_dell_omsa.conf

#3、启动nzabbix-agent服务
chmod -R 755 /etc/zabbix
systemctl enable zabbix-agent
systemctl restart zabbix-agent

#zabbix_get -s agent端地址 -k "hardware_battery"  



#安装OMSA组件：

#基础包安装
# yum  -y install libcmpiCppImpl0 libwsman1 sblim-sfcb sblim-sfcc openwsman-client openwsman-server 
#yum源安装
# wget -q -O - http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | bash
#omsa安装
# yum -y install srvadmin-all 
#bios升级包
# yum -y install dell-system-update 

#启动与停止
#/opt/dell/srvadmin/sbin/srvadmin-services.sh start
#/opt/dell/srvadmin/sbin/srvadmin-services.sh stop
#/opt/dell/srvadmin/sbin/srvadmin-services.sh enable
#浏览器输入https://IP地址:1311  用户名和密码是系统的用户名和密码。

#安装MegaCli软件包
#yum -y install MegaCli-8.07.10-1.noarch.rpm