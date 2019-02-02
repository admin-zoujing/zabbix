#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、安装zabbix-agent客户端
sourceinstall=/usr/local/src/lnmp/zabbix/oracle-zabbix
chmod 777 $sourceinstall
cd $sourceinstall
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#2、配置zabbix-agent监听（需要修改允许监听的服务器地址）
sed -i 's|Server=127.0.0.1|Server=192.168.8.50|' /etc/zabbix/zabbix_agentd.conf
sed -i 's|ServerActive=127.0.0.1|ServerActive=192.168.8.50|' /etc/zabbix/zabbix_agentd.conf
sed -i 's|Hostname=Zabbix server|Hostname=192.168.8.6|' /etc/zabbix/zabbix_agentd.conf

#3、配置tzdb.dat
cd $sourceinstall
yum -y install tzdata-java-2018e-3.el7.noarch.rpm

#4、安装orabbix软件
mkdir -pv /opt/orabbix
unzip orabbix-1.2.3.zip -d /opt/orabbix
chmod -R a+x /opt/orabbix
cd /opt/orabbix/conf
cp config.props.sample config.props
sed -i 's|ZabbixServerList=ZabbixServer1,ZabbixServer2|ZabbixServerList=ZabbixServer1|' /opt/orabbix/conf/config.props
sed -i 's|ZabbixServer1.Address=IP_ADDRESS_OF_ZABBIX_SERVER|ZabbixServer1.Address=192.168.8.50|' /opt/orabbix/conf/config.props
sed -i 's|ZabbixServer1.Port=PORT_OF_ZABBIX_SERVER|ZabbixServer1.Port=10051|' /opt/orabbix/conf/config.props

sed -i 's|DatabaseList=DB1,DB2,DB3|DatabaseList=192.168.8.6|' /opt/orabbix/conf/config.props
sed -i 's|DB1.Url=jdbc:oracle:thin:@server.domain.example.com:<LISTENER_PORT>:DB1|192.168.8.6.Url=jdbc:oracle:thin:@192.168.8.6:1521:orcl|' /opt/orabbix/conf/config.props
sed -i 's|DB1.User=zabbix|192.168.8.6.User=zabbix|' /opt/orabbix/conf/config.props
sed -i 's|DB1.Password=zabbix_password|192.168.8.6.Password=zabbix|' /opt/orabbix/conf/config.props

sed -i 's|DB1.MaxActive=10|192.168.8.6.MaxActive=10|' /opt/orabbix/conf/config.props
sed -i 's|DB1.MaxWait=100|192.168.8.6.MaxWait=100|' /opt/orabbix/conf/config.props
sed -i 's|DB1.MaxIdle=1|192.168.8.6.MaxIdle=1|' /opt/orabbix/conf/config.props
sed -i 's|DB1.QueryListFile=./conf/query.props|192.168.8.6.QueryListFile=./conf/query.props|' /opt/orabbix/conf/config.props

cp /opt/orabbix/init.d/orabbix /etc/init.d/orabbix

#5、数据库操作
sqlplus / as sysdba
create user zabbix identified by zabbix default tablespace system temporary tablespace temp profile default account unlock;
GRANT CONNECT TO ZABBIX;
GRANT RESOURCE TO ZABBIX;
ALTER USER ZABBIX DEFAULT ROLE ALL;
GRANT SELECT ANY TABLE TO ZABBIX;
GRANT CREATE SESSION TO ZABBIX;
GRANT SELECT ANY DICTIONARY TO ZABBIX;
GRANT UNLIMITED TABLESPACE TO ZABBIX; 
GRANT SELECT ANY DICTIONARY TO ZABBIX;
exec dbms_network_acl_admin.create_acl(acl => 'resolve.xml',description => 'resolve acl', principal =>'ZABBIX', is_grant => true, privilege => 'resolve');
exec dbms_network_acl_admin.assign_acl(acl => 'resolve.xml', host =>'*');
commit;

#6、监控数据库表空间
#echo 'export PATH
#export ORACLE_BASE=/home/oracle/app
#export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1
#export LANG="en_US"
#export ORACLE_SID=orcl
#export NLS_LANG="AMERICAN_AMERICA.UTF8"
#export NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"
#export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$PATH
#> /home/oracle/app/tablespace.log

#su - oracle -c "sqlplus / as sysdba" <<EOF
#@/etc/zabbix/zabbix_agentd.d/tablespace.sql
#EOF

#' > /etc/zabbix/zabbix_agentd.d/tablespace.sh

#cat > /etc/zabbix/zabbix_agentd.d/tablespace.sql <<EOF
#set serveroutput on
#set heading off
#set pagesize 300
#--set linesize 200
#set feedback off
#column tablespace_name for a40
#column FREE(G) for a10
#column FREE_PCT(%) for a15
#column SIZE format 99,999,999,999
#column FREE format 99,999,999,999
#column USED format 99,999,999,999
#column FREE_PCT format 99,999,999,999
#set echo off
#spool /home/oracle/app/tablespace.log
#SELECT TABLESPACE_NAME,
#TO_CHAR(ROUND(BYTES/1024,2),'99990.00') "TOTAL(G)",
#TO_CHAR(ROUND(FREE/1024,2),'99990.00') "FREE(G)",
#TO_CHAR(ROUND(100*FREE/BYTES)/100,'99990.00') "FREE_PCT(%)"
#FROM(SELECT A.TABLESPACE_NAME TABLESPACE_NAME,
#FLOOR(A.BYTES/(1024*1024))BYTES,
#FLOOR(B.FREE/(1024*1024))FREE,
#FLOOR((A.BYTES-B.FREE)/(1024*1024))USED
#FROM(SELECT TABLESPACE_NAME TABLESPACE_NAME,SUM(BYTES) BYTES
#FROM DBA_DATA_FILES
#GROUP BY TABLESPACE_NAME) A,
#(SELECT TABLESPACE_NAME TABLESPACE_NAME,SUM(BYTES) FREE
#FROM DBA_FREE_SPACE
#GROUP BY TABLESPACE_NAME) B
#WHERE A.TABLESPACE_NAME=B.TABLESPACE_NAME)
#ORDER BY FLOOR(FREE/BYTES);
#spool off
#quit
#EOF


#7、启动orabbix服务及zabbix-agent服务
chown -R zabbix:zabbix /etc/zabbix
service orabbix start
chkconfig orabbix on
systemctl restart orabbix 
systemctl enable orabbix 

systemctl restart zabbix-agent.service 
systemctl enable zabbix-agent.service 

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent
firewall-cmd --permanent --query-port=10050/tcp
firewall-cmd --reload

#服务器测试： /usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k nginx.status[requests]