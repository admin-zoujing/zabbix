#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/nginx-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#2、配置zabbix-agent监听（需要修改允许监听的服务器地址）
cat  > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_nginx.conf <<EOF
LogFile=/var/log/zabbix/zabbix_agentd_nginx.log
#zabbix server的ip地址，多个ip使用逗号分隔
Server=192.168.8.50
ServerActive=192.168.8.50
#zabbix agent的ip地址
Hostname=192.168.8.51
ListenPort=10050
HostMetadataItem=system.uname
# Nginx_status
UserParameter=nginx.status[*],/etc/zabbix/externalscripts/ngx_status.sh \$1 
EOF

#3、配置zabbix-agent监听shell脚本（需要修改主机客户端地址）
mkdir -pv /etc/zabbix/externalscripts
cat  > /etc/zabbix/externalscripts/ngx_status.sh <<EOF
#!/bin/bash
# AUTHOR：
# Description：zabbix 监控 nginx 性能以及进程状态
# Note：此脚本需要配置在被监控端，否则 ping 检测将会得到不符合预期的结果

HOST="192.168.8.51"
PORT="8888"
# 检测 nginx 进程是否存在
function ping {
/sbin/pidof nginx | wc -l
}
# 检测 nginx 性能
function active {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| grep 'Active' | awk '{print \$NF}'
}
function reading {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| grep 'Reading' | awk '{print \$2}'
}
function writing {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| grep 'Writing' | awk '{print \$4}'
}
function waiting {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| grep 'Waiting' | awk '{print \$6}'
}
function accepts {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| awk NR==3 | awk '{print \$1}'
}
function handled {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| awk NR==3 | awk '{print \$2}'
}
function requests {
/usr/bin/curl "http://\$HOST:\$PORT/ngx_status/" 2>/dev/null| awk NR==3 | awk '{print \$3}'
}
# 执行 function
\$1
EOF
chmod -R 500 /etc/zabbix/externalscripts

#4、配置nginx包含目录
mkdir -pv /usr/local/nginx/conf/conf.d
chown -R nginx:nginx  /usr/local/nginx/conf/conf.d
sed -i '/http {/a\    include /usr/local/nginx/conf/conf.d/*.conf;' /usr/local/nginx/conf/nginx.conf

#5、配置nginx监听信息（需要修改允许监听的服务器地址）
#注意主配置文件里面的server应该踢出来：cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/conf.d/
cat > /usr/local/nginx/conf/conf.d/nginx_status.conf <<EOF
server {
    listen  *:8888 default_server;
    server_name _;
    location /ngx_status
    {
        stub_status on;
        access_log off;
        allow all;
        #deny all;
    }
} 
EOF
chown -R nginx:nginx  /usr/local/nginx/conf/conf.d
systemctl restart nginx.service 

#6、启动nginx服务及zabbix-agent服务
chown -R zabbix:zabbix /etc/zabbix
systemctl reload nginx && systemctl reload php-fpm && systemctl enable zabbix-agent
systemctl restart zabbix-agent.service 
systemctl enable zabbix-agent.service 

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent
firewall-cmd --permanent --query-port=10050/tcp
firewall-cmd --reload

#服务器测试： /usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k nginx.status[requests]