#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、配置nginx包含目录
sed -i '/http {/a\    include /usr/local/nginx/conf/conf.d/*.conf;' /usr/local/nginx/conf/nginx.conf

sed -i 's|user = nobody|user = php|' /usr/local/php/etc/php-fpm.d/www.conf
sed -i 's|group = nobody|group = php|' /usr/local/php/etc/php-fpm.d/www.conf
sed -i 's|;pm.status_path = /status|pm.status_path = /status|g' /usr/local/php/etc/php-fpm.d/www.conf

#2、配置nginx监听信息（需要修改允许监听的服务器地址）
cat > /usr/local/nginx/conf/conf.d/phpfpm_status.conf <<EOF
server {
    listen  *:8008 default_server;
    server_name _;
    location ~ ^/(status)$ 
    {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        allow all;
        #deny all;
    }
}  
EOF
chown -R nginx:nginx /usr/local/nginx/conf/conf.d/
systemctl restart nginx 
systemctl restart php-fpm

#3、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/php-fpm-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#4、配置zabbix-agent监听（需要修改允许监听的服务器地址）
cat > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_php-fpm.conf <<EOF
LogFile=/var/log/zabbix/zabbix_agentd_php-fpm.log
#zabbix server的ip地址，多个ip使用逗号分隔
Server=192.168.8.50
ServerActive=192.168.8.50
#zabbix agent的ip地址
Hostname=192.168.8.51
ListenPort=10050
HostMetadataItem=system.uname
#HostMetadata: Linux hehehehehehehehe xxxxx
UserParameter=php-fpm.status[*],/usr/bin/curl -s "http://127.0.0.1:8008/status?xml" | grep "<\$1>" | awk -F'>|<' '{ print \$\$3}'
EOF

#5、启动nginx服务及zabbix-agent服务
chmod -R 755 /etc/zabbix
systemctl reload nginx && systemctl reload php-fpm && systemctl enable zabbix-agent

#服务器测试： /usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k 'php-fpm.status[start-since]'