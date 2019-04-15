#! /bin/bash
#Centos7 + zabbix_server安装脚本
##http://mirrors.aliyun.com/zabbix/zabbix/3.4/
sourceinstall=/usr/local/src/lnmp/zabbix
chmod -R 777 $sourceinstall
ntpdate ntp1.aliyun.com
yum -y install net-snmp* libevent* javac* libssh2-devel.x86_64 OpenIPMI-devel
hostname zabbixserver && export HOSTNAME=zabbixserver
echo "`ifconfig|grep 'inet'|head -1|awk '{print $2}'|cut -d: -f2` zabbixserver" >> /etc/hosts


#为PHP增加LDAP扩展模块支持
cd /usr/local/php/php-7.2.14/ext/ldap/
/usr/local/php/bin/phpize
cp -frp /usr/lib64/libldap* /usr/lib/
./configure --with-php-config=/usr/local/php/bin/php-config --with-ldap
make && make install
echo 'extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/ldap.so' >> /usr/local/php/etc/php.ini


#1、解压安装
cd $sourceinstall
mkdir -pv /usr/local/zabbix
tar -zxvf zabbix-3.4.15.tar.gz -C /usr/local/zabbix/

#2、创建用户
useradd zabbix -s /sbin/nologin
chown -R zabbix:zabbix /usr/local/zabbix

#3、创建数据库
mysql -uroot -pRoot_123456*0987 -e "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"
mysql -uroot -pRoot_123456*0987 -e "GRANT ALL ON zabbix.* TO zabbix@localhost IDENTIFIED BY 'zabbix_123456*0987';"
mysql -uroot -pRoot_123456*0987 -e "flush privileges;"

cd /usr/local/zabbix/zabbix-3.4.15/database/mysql/
mysql -uzabbix -pzabbix_123456*0987 zabbix < schema.sql
mysql -uzabbix -pzabbix_123456*0987 zabbix < images.sql
mysql -uzabbix -pzabbix_123456*0987 zabbix < data.sql
cd /usr/local/zabbix/zabbix-3.4.15/ 
./configure --prefix=/usr/local/zabbix/ --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-ssh2 --with-libxml2 --enable-java --with-openipmi
make && make install

#4、zabbix命令加入bash
cat >> /etc/profile.d/zabbix.sh <<EOF
  PATH=/usr/local/zabbix/sbin/:\$PATH
  export PATH
EOF
source /etc/profile.d/zabbix.sh

#5、启动zabbix
#配置zabbix_server配置文件
sed -i 's|# StartIPMIPollers=0|StartIPMIPollers=5|' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's|# DBPassword=|DBPassword=zabbix_123456*0987|' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's|# DBPort=3306|DBPort=3306|' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's|# JavaGateway=|JavaGateway=127.0.0.1|' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's|# JavaGatewayPort=10052|JavaGatewayPort=10052|' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's|# StartJavaPollers=0|StartJavaPollers=5|' /usr/local/zabbix/etc/zabbix_server.conf

echo "/usr/local/mysql/lib" >> /etc/ld.so.conf
ldconfig

cat >> /usr/lib/systemd/system/zabbix-server.service <<EOF
[Unit]
Description=zabbix_server
After=syslog.target
After=network.target

[Service]
Type=forking
Restart=on-failure
PIDFile=/tmp/zabbix_server.pid
KillMode=control-group
ExecStart=/usr/local/zabbix/sbin/zabbix_server -c /usr/local/zabbix/etc/zabbix_server.conf
ExecStop=/bin/kill -SIGTERM \$MAINPID
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
chmod 755 /usr/lib/systemd/system/zabbix-server.service
chown -Rf zabbix:zabbix /usr/local/zabbix
systemctl daemon-reload && systemctl enable zabbix-server.service && systemctl start zabbix-server.service 

cat >> /usr/lib/systemd/system/zabbix-agent.service <<EOF
[Unit]
Description=Zabbix Agent
After=syslog.target
After=network.target

[Service]
Type=forking
Restart=on-failure
PIDFile=/tmp/zabbix_agentd.pid
KillMode=control-group
ExecStart=/usr/local/zabbix/sbin/zabbix_agentd -c /usr/local/zabbix/etc/zabbix_agentd.conf
ExecStop=/bin/kill -SIGTERM \$MAINPID
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
chmod 755 /usr/lib/systemd/system/zabbix-agent.service
chown -Rf zabbix:zabbix /usr/local/zabbix
systemctl daemon-reload && systemctl enable zabbix-agent.service && systemctl start zabbix-agent.service 



#6、复制前端文件
mkdir -pv /usr/local/nginx/html/zabbix
cp -rp /usr/local/zabbix/zabbix-3.4.15/frontends/php/* /usr/local/nginx/html/zabbix/
chmod -Rf 775 /usr/local/nginx/html/zabbix
chown -Rf nginx:nginx /usr/local/nginx/html/zabbix

#7、配置nginx配置文件（只需更改web文件路径即可）
#sed -i '44c \            root   /usr/local/nginx/html;' /usr/local/nginx/conf/nginx.conf
#sed -i '54c \            root   /usr/local/nginx/html;' /usr/local/nginx/conf/nginx.conf
#sed -i '66c \            root   /usr/local/nginx/html;' /usr/local/nginx/conf/nginx.conf

#8、启动lamp或lnmp后，通过浏览器访问http://<server_ip_or_name>/zabbix即可进行安装。
sed -i 's|max_execution_time = 30|max_execution_time = 300|' /usr/local/php/etc/php.ini
sed -i 's|max_input_time = 60|max_input_time = 300|' /usr/local/php/etc/php.ini
sed -i 's|post_max_size = 8M|post_max_size = 16M|' /usr/local/php/etc/php.ini
sed -i 's|;extension=php_ldap.dll|extension=php_ldap.dll|' /usr/local/php/etc/php.ini
sed -i 's|;date.timezone =|date.timezone =Asia/Shanghai|' /usr/local/php/etc/php.ini

#9、  解决zabbix中文乱码方法
cp $sourceinstall/simkai.ttf /usr/local/nginx/html/zabbix/fonts
sed -i  's|DejaVuSans|simkai|' /usr/local/nginx/html/zabbix/include/defines.inc.php
chmod -Rf 777 /usr/local/nginx/html/zabbix
chown -Rf nginx:nginx /usr/local/nginx/zabbix
systemctl daemon-reload && systemctl restart php-fpm.service && systemctl restart nginx.service
#用户名:Admin    注A大写
#密码：zabbix

