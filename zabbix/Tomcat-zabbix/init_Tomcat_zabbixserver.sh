#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、安装客户端zabbix-java-gateway
cd /usr/local/src/lnmp/zabbix
yum -y install zabbix-java-gateway-3.4.15-1.el7.x86_64.rpm

sed -i 's|# LISTEN_IP="0.0.0.0"|LISTEN_IP="0.0.0.0"|' /etc/zabbix/zabbix_java_gateway.conf
sed -i 's|# LISTEN_PORT=10052|LISTEN_PORT=10052|' /etc/zabbix/zabbix_java_gateway.conf
sed -i 's|# START_POLLERS=5|START_POLLERS=5|' /etc/zabbix/zabbix_java_gateway.conf
systemctl enable zabbix-java-gateway.service 
systemctl restart zabbix-java-gateway.service 

#2、客户端配置Tomcat jmx
sed -i '117c CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=12345"' /usr/local/apache-tomcat-9.0.14/bin/catalina.sh 
systemctl restart tomcat

#3、服务器配置zabbixserver 必须编译安装时安装--with-libxml2 --enable-java
sed -i '/JavaGateway=127.0.0.1/a\JavaGateway=192.168.8.51' /usr/local/zabbix/etc/zabbix_server.conf
# sed -i 's|# JavaGatewayPort=10052|JavaGatewayPort=10052|' /usr/local/zabbix/etc/zabbix_server.conf
# sed -i 's|# StartJavaPollers=0|StartJavaPollers=5|' /usr/local/zabbix/etc/zabbix_server.conf
systemctl restart zabbix-server.service 

firewall-cmd --permanent --zone=public --add-port=10052/tcp --permanent
firewall-cmd --permanent --query-port=10052/tcp
firewall-cmd --reload


#JMX接口添加网关IP地址，DNS12345  模板添加Template App Apache Tomcat JMX和Template App Generic Java JMX

#cannot connect to [[192.168.8.51]:10052]: [113] No route to host  问题；防火墙没关
#java.io.IOException: Failed to retrieve RMIServer stub: javax.naming.ServiceUnavailableException [Root exception is java.rmi.ConnectException: Connection refused to host: 192.168.8.51; nested exception is: java.net.ConnectException: Connection refused (Connection refused)]
#tomcat jmx没有配置好，不能配置最后
