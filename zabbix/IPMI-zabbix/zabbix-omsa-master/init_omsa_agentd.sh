#!/bin/bash

#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/IPMI-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm
#zabbix server的ip地址，多个ip使用逗号分隔
sed -i 's|Server=127.0.0.1|Server=192.168.30.100| ' /etc/zabbix/zabbix_agentd.conf
sed -i 's|ServerActive=127.0.0.1|ServerActive=192.168.30.100| ' /etc/zabbix/zabbix_agentd.conf
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

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent;
firewall-cmd --permanent --query-port=10050/tcp;
firewall-cmd --reload;
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



#BIOS 界面设置 IPMI,重启F2进去System Setup界面,选择iDRAC Settings:进入后,先配置Network:先后在这个页面中配置了：启动iDrac网卡,设置idrac的ip,启用ipmi

#1、yum install -y OpenIPMI ipmitool 
# systemctl enable ipmi  && systemctl start ipmi    
#2 使用ipmitool 也可以设置ipmi 的 ip（如果是裸机，就只能在BIOS 界面设置了）
# ipmitool lan set 1 ipsrc static 
# ipmitool lan set 1 ipaddr 10.11.1.99          
# ipmitool lan set 1 netmask 255.255.0.0         
# ipmitool lan set  1 defgw ipaddr 10.11.1.1   
#3、查看ipmitool lan print 1
#4、重启 ipmi 服务: systemctl restart ipmi
#5、测试 ipmi
#     ipmitool -I lanplus -H x.x.x.x  -U  root -P  password chassis power status
#     DELL 默认的 ipmi 用户名密码是 root/calvin, 可以在BIOS user configuration 中修改，也可以通过 ipmitool 修改
#    lanplus 可以替换为 lan 测试
#    ipmitool user list 1           # 1 是channel ID
#    ipmitool user set name 2 root   # 2 是用户的id
#    ipmitool user set password 2 $newPassword
#    ipmitool user enable 2
#    ipmitool channel setaccess 1 2 callin=on ipmi=on link=on privilege=2
#6 ipmitool lan print 1 
#7、可以通过web 界面访问 DRAC 页面   https://$ipmi_IP
#8.DELL 提供 win 界面的 ipmish.exe 和 ipmitool.exe (可以在官网下载)
#9、ipmitool 常用命令
#ipmitool user list 1         通道1用户列表 语法： list    [<channel number>]
#ipmitool user priv 2 4 1     设置权限，语法:   priv     <user id> <privilege level> [<channel number>]
#ipmitool lan set 1 access on 设置channel 1允许访问

#服务端配置
sed -i '/# StartIPMIPollers=0/aStartIPMIPollers=5'  /usr/local/zabbix/etc/zabbix_server.conf
