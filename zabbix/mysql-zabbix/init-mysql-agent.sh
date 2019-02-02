#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
# AUTHOR：
# Description：zabbix 监控 mysql 性能
# Note：此脚本需要配置在被监控端

#1、安装zabbix-agent
cd /usr/local/src/lnmp/zabbix/mysql-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#zabbix server的ip地址，多个ip使用逗号分隔
sed -i 's|Server=127.0.0.1|Server=192.168.8.50| ' /etc/zabbix/zabbix_agentd.conf
sed -i 's|ServerActive=127.0.0.1|ServerActive=192.168.8.50| ' /etc/zabbix/zabbix_agentd.conf
#zabbix agent的ip地址
sed -i 's|Hostname=Zabbix server|Hostname=192.168.8.51| ' /etc/zabbix/zabbix_agentd.conf


#2、配置mysql脚本(根据需要进行修改IP、密码等)
mkdir -pv /etc/zabbix/externalscripts
echo '#!/bin/bash
# -------------------------------------------------------------------------------
# FileName: check_mysql.sh
# Revision: 1.0
# Description:
# -------------------------------------------------------------------------------
# License: GPL

MYSQL_USER="root"
MYSQL_PWD="Root_123456*0987"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
# 数据连接
MYSQL_CONN="/usr/local/mysql/bin/mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -h${MYSQL_HOST} -P${MYSQL_PORT}"
# 参数是否正确
if [ $# -ne "1" ];then
    echo "arg error!"
fi
# 获取数据
case $1 in
   Uptime)
       result=`${MYSQL_CONN} status 2>/dev/null|cut -f2 -d":"|cut -f1 -d"T"`
       echo $result
       ;;
   Com_update)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_update"|cut -d"|" -f3`
       echo $result
       ;;
   Slow_queries)
       result=`${MYSQL_CONN} status 2>/dev/null|cut -f5 -d":"|cut -f1 -d"O"`
       echo $result
       ;;
   Com_select)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_select"|cut -d"|" -f3`
       echo $result
       ;;
   Com_rollback)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_rollback"|cut -d"|" -f3`
       echo $result
       ;;
   Questions)
       result=`${MYSQL_CONN} status 2>/dev/null|cut -f4 -d":"|cut -f1 -d"S"`
       echo $result
       ;;
   Com_insert)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_insert"|cut -d"|" -f3`
       echo $result
       ;;
   Com_delete)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_delete"|cut -d"|" -f3`
       echo $result
       ;;
   Com_commit)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_commit"|cut -d"|" -f3`
       echo $result
       ;;
   Bytes_sent)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Bytes_sent" |cut -d"|" -f3`
       echo $result
       ;;
   Bytes_received)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Bytes_received" |cut -d"|" -f3`
       echo $result
       ;;
   Com_begin)
       result=`${MYSQL_CONN} extended-status 2>/dev/null|grep -w "Com_begin"|cut -d"|" -f3`
       echo $result
       ;;
   *)
       echo "Usage:$0(Uptime|Com_update|Slow_queries|Com_select|Com_rollback|Questions|Com_insert|Com_delete|Com_commit|Bytes_sent|Bytes_received|Com_begin)"
       ;;
esac
' > /etc/zabbix/externalscripts/chk_mysql.sh
chmod -R 500 /etc/zabbix/externalscripts

#2、配置zabbix-agentd
cat > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_mysql.conf <<EOF
LogFile=/var/log/zabbix/zabbix_agentd_mysql.log
ListenPort=10050
HostMetadataItem=system.uname
# 获取 mysql 版本
UserParameter=mysqld.version,mysql -V
# 获取 mysql 性能指标,这个是上面定义好的脚本
UserParameter=mysqld.status[*],/etc/zabbix/externalscripts/chk_mysql.sh \$1
# 获取 mysql 运行状态
UserParameter=mysqld.ping,netstat -ntpl |grep 3306 |grep mysql |wc |awk '{print \$1}'                                
EOF

#3、赋权、重启
chmod +s /bin/netstat
chown -R zabbix:zabbix /etc/zabbix
#GRANT PROCESS,SUPER,REPLICATION CLIENT ON *.* TO root@'127.0.0.1' IDENTIFIED BY 'Root_123456*0987'
systemctl restart zabbix-agent.service
systemctl enable zabbix-agent.service

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent
firewall-cmd --permanent --query-port=10050/tcp
firewall-cmd --reload


#注意细节
##########模板使用导入的，系统自带的模板使用的键值mysql，而脚本使用的mysqld（使用mysql启动不了）######
#ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin
#ln -s /var/lib/mysql/mysql.sock /tmp/mysql.sock
#vim /etc/selinux/config
#SELINUX=disabled
#SELINUXTYPE=targeted  注释掉

#服务器测试： /usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k mysqld.ping