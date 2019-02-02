#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/mongodb-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#2、配置zabbix-agent监听（需要修改允许监听的服务器地址）
echo 'LogFile=/var/log/zabbix/zabbix_agentd_mongodb.log
#zabbix server的ip地址，多个ip使用逗号分隔
Server=192.168.8.50
ServerActive=192.168.8.50
#zabbix agent的ip地址
Hostname=192.168.8.51
ListenPort=10050
HostMetadataItem=system.uname
# Return MongoDB statistics
UserParameter=MongoDB.Status[*],/etc/zabbix/externalscripts/mongodb.sh $1 $2 $3
' > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_mongodb.conf 

#3、配置zabbix-agent监听shell脚本（需要修改主机客户端地址）
mkdir -pv /etc/zabbix/externalscripts
echo '#!/bin/bash
case $# in
  1)
    output=$(/bin/echo "db.serverStatus().$1" |/usr/local/mongodb/bin/mongo 127.0.0.1:27017/admin |sed -n "5p")
    ;;
  2)
    output=$(/bin/echo "db.serverStatus().$1.$2" |/usr/local/mongodb/bin/mongo 127.0.0.1:27017/admin |sed -n "5p")
    ;;
  3)
    output=$(/bin/echo "db.serverStatus().$1.$2.$3" |/usr/local/mongodb/bin/mongo 127.0.0.1:27017/admin |sed -n "5p")
    ;;
esac
  
#check if the output contains "NumberLong"
if [[ "$output" =~ "NumberLong"   ]];then
  echo $output|sed -n "s/NumberLong(//p"|sed -n "s/)//p"
else
  echo $output
fi
' > /etc/zabbix/externalscripts/mongodb.sh
chmod -R 744 /etc/zabbix/externalscripts

#3、启动mongodb服务及zabbix-agent服务
chmod +s /usr/local/mongodb/bin/mongo
chown -R zabbix:zabbix /etc/zabbix
systemctl enable zabbix-agent
systemctl restart zabbix-agent.service 

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent
firewall-cmd --permanent --query-port=10050/tcp
firewall-cmd --reload

#服务器测试：/usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k MongoDB.Status[mem.virtual]