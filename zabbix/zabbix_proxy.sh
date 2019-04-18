#! /bin/bash
#Centos7 + zabbix_proxy安装脚本 通常用于跨机房或主机大于500台
##http://mirrors.aliyun.com/zabbix/zabbix/3.4/
##wget https://sourceforge.net/projects/zabbix/files/zabbix-4.0.6.tar.gz
sourceinstall=/usr/local/src/lnmp/zabbix
chmod -R 777 $sourceinstall
ntpdate ntp1.aliyun.com
hostname zabbix_proxy_192.168.10.19 && export HOSTNAME=zabbix_proxy_192.168.10.19
echo "`ifconfig|grep 'inet'|head -1|awk '{print $2}'|cut -d: -f2` zabbix_proxy_192.168.10.19" >> /etc/hosts

#1、安装
cd $sourceinstall
yum -y install zabbix-proxy-mysql-4.0.6-1.el7.x86_64.rpm 

#2、安装数据库，创建数据库
mysql -uroot -pRoot_123456*0987 -e "CREATE DATABASE zabbix_proxy CHARACTER SET utf8 COLLATE utf8_bin;"
mysql -uroot -pRoot_123456*0987 -e "GRANT ALL ON zabbix_proxy.* TO zabbix@localhost IDENTIFIED BY 'zabbix_123456*0987';"
mysql -uroot -pRoot_123456*0987 -e "flush privileges;"
zcat /usr/share/doc/zabbix-proxy-mysql-4.0.6/schema.sql.gz | mysql -uzabbix -pzabbix_123456*0987 zabbix_proxy  

#3、配置zabbix_proxy配置文件
sed -i 's|Server=127.0.0.1|Server=192.168.30.100|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|Hostname=Zabbix proxy|Hostname=192.168.10.19|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|DBName=zabbix_proxy|DBName=zabbix_proxy|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|DBUser=zabbix|DBUser=zabbix|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|# DBPassword=|DBPassword=zabbix_123456*0987|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|# DBPort=|DBPort=3306|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|# ConfigFrequency=3600|ConfigFrequency=120|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|DataSenderFrequency=1|DataSenderFrequency=60|' /etc/zabbix/zabbix_proxy.conf 
sed -i 's|SNMPTrapperFile=/var/log/snmptrap/snmptrap.log|SNMPTrapperFile=/var/log/zabbix/snmptrap.log|' /etc/zabbix/zabbix_proxy.conf 

systemctl enable zabbix-proxy.service 
systemctl restart zabbix-proxy.service 

firewall-cmd --permanent --zone=public --add-port=3306/tcp --permanent;
firewall-cmd --permanent --query-port=3306/tcp;
firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent;
firewall-cmd --permanent --query-port=10050/tcp;
firewall-cmd --permanent --zone=public --add-port=10051/tcp --permanent;
firewall-cmd --permanent --query-port=10051/tcp;
firewall-cmd --reload;

#zabbix server web GUI上添加zabbix proxy agent代理
#管理-->agent代理程序-->192.168.10.19--代理地址"IP"-->添加-->启用主机

#zabbix-server web GUI 添加基于proxy的agent
#配置-->主机-->创建主机-->主机名称"192.168.10.67"-->可见名称-->群组-->agent代理程序的接口"192.168.10.67"-->由agent代理程序监测"192.168.10.19"-->添加


#配置agentd.conf
#Server=192.168.10.19        #zabbix-proxy地址
#ServerActive=192.168.10.19  #zabbix-proxy地址
#Hostname=192.168.10.18      #zabbix-agent地址