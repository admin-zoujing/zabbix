#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/redis-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#2、配置zabbix-agent监听（需要修改允许监听的服务器地址）
echo 'LogFile=/var/log/zabbix/zabbix_agentd_redis.log
#zabbix server的ip地址，多个ip使用逗号分隔
Server=192.168.8.50
ServerActive=192.168.8.50
#zabbix agent的ip地址
Hostname=192.168.8.51
ListenPort=10050
HostMetadataItem=system.uname
#监控redis状态，我们可以根据这个参数对应的监控项创建redis状态触发器。
UserParameter=redis.status,/usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 -a sanxin ping 2>/dev/null|grep -c PONG  
#item参数如何get
UserParameter=redis_info[*],/etc/zabbix/externalscripts/redis-status.sh $1 $2 
' > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_redis.conf 

#3、配置zabbix-agent监听shell脚本（需要修改主机客户端地址）
mkdir -pv /etc/zabbix/externalscripts
cat > /etc/zabbix/externalscripts/redis-status.sh <<EOF
#!/bin/bash
HOST="127.0.0.1"
PORT="6379"
PASSWD="sanxin"

if [[ \$# == 1 ]];then
    case \$1 in
 cluster)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w cluster|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
 uptime_in_seconds)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w uptime_in_seconds|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
 connected_clients)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w connected_clients|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
 client_longest_output_list)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w client_longest_output_list|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
 client_biggest_input_buf)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w client_biggest_input_buf|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
 blocked_clients)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w blocked_clients|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
#内存
 used_memory)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w used_memory|awk -F":" '{print \$NF}'|awk 'NR==1'\`
            echo \$result 
            ;; 
 used_memory_human)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w used_memory_human|awk -F":" '{print \$NF}'|awk -F'K' '{print \$1}'\` 
            echo \$result 
            ;; 
 used_memory_rss)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w used_memory_rss|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;; 
 used_memory_peak)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w used_memory_peak|awk -F":" '{print \$NF}'|awk 'NR==1'\`
            echo \$result 
            ;; 
 used_memory_peak_human)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w used_memory_peak_human|awk -F":" '{print \$NF}'|awk -F'K' '{print \$1}'\`
            echo \$result 
            ;; 
 used_memory_lua)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w used_memory_lua|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;;     
 mem_fragmentation_ratio)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w mem_fragmentation_ratio|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;;   
#rdb
 rdb_changes_since_last_save)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w rdb_changes_since_last_save|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;;   
 rdb_bgsave_in_progress)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w rdb_bgsave_in_progress|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;;   
 rdb_last_save_time)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w rdb_last_save_time|awk -F":" '{print \$NF}'\`
            echo \$result 
            ;;   
 rdb_last_bgsave_status)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "rdb_last_bgsave_status" | awk -F':' '{print \$2}' | /bin/grep -w -c ok\`
            echo \$result 
            ;;   
 rdb_current_bgsave_time_sec)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "rdb_current_bgsave_time_sec" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
#rdbinfo
 aof_enabled)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_enabled" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_rewrite_scheduled)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_rewrite_scheduled" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_last_rewrite_time_sec)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_last_rewrite_time_sec" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_current_rewrite_time_sec)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_current_rewrite_time_sec" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_last_bgrewrite_status)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_last_bgrewrite_status" | awk -F':' '{print \$2}' | /bin/grep -w -c ok\`
            echo \$result 
            ;; 
#aofinfo
 aof_current_size)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_current_size" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_base_size)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_base_size" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_pending_rewrite)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_pending_rewrite" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_buffer_length)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_buffer_length" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 aof_rewrite_buffer_length)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_rewrite_buffer_length" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;   
 aof_pending_bio_fsync)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_pending_bio_fsync" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 aof_delayed_fsync)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "aof_delayed_fsync" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;                     
#stats
 total_connections_received)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "total_connections_received" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 total_commands_processed)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "total_commands_processed" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 instantaneous_ops_per_sec)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "instantaneous_ops_per_sec" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 rejected_connections)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "rejected_connections" | awk -F':' '{print \$2}'\` 
            echo \$result 
            ;; 
 expired_keys)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "expired_keys" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;; 
 evicted_keys)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "evicted_keys" | awk -F':' '{print \$2}'\` 
            echo \$result 
            ;; 
 keyspace_hits)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "keyspace_hits" | awk -F':' '{print \$2}'\` 
            echo \$result 
            ;; 
 keyspace_misses)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "keyspace_misses" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 pubsub_channels)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "pubsub_channels" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 pubsub_channels)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "pubsub_channels" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 pubsub_patterns)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "pubsub_patterns" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 latest_fork_usec)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "latest_fork_usec" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;           
 connected_slaves)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "connected_slaves" | awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 master_link_status)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "master_link_status"|awk -F':' '{print \$2}'|/bin/grep -w -c up\`
            echo \$result 
            ;;
 master_last_io_seconds_ago)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "master_last_io_seconds_ago"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 master_sync_in_progress)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "master_sync_in_progress"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 slave_priority)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "slave_priority"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
#cpu
 used_cpu_sys)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "used_cpu_sys"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 used_cpu_user)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "used_cpu_user"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 used_cpu_sys_children)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "used_cpu_sys_children"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
 used_cpu_user_children)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "used_cpu_user_children"|awk -F':' '{print \$2}'\`
            echo \$result 
            ;;
        *)
        echo "Usage:\$0{uptime_in_seconds|connected_clients|client_longest_output_list|client_biggest_input_buf|blocked_clients|used_memory|used_memory_human|used_memory_rss|used_memory_peak|used_memory_peak_human|used_memory_lua|mem_fragmentation_ratio|rdb_changes_since_last_save|rdb_bgsave_in_progress|rdb_last_save_time|rdb_last_bgsave_status|rdb_current_bgsave_time_sec|aof_enabled|aof_rewrite_scheduled|aof_last_rewrite_time_sec|aof_current_rewrite_time_sec|aof_last_bgrewrite_status|aof_current_size|aof_base_size|aof_pending_rewrite|aof_buffer_length|aof_rewrite_buffer_length|aof_pending_bio_fsync|aof_delayed_fsync|rejected_connections|instantaneous_ops_per_sec|total_connections_received|total_commands_processed|expired_keys|evicted_keys|keyspace_hits|keyspace_misses|pubsub_channels|pubsub_patterns|latest_fork_usec|connected_slaves|master_link_status|master_sync_in_progress|master_last_io_seconds_ago|connected_slaves|slave_priority|used_cpu_user|used_cpu_sys|used_cpu_sys_children|used_cpu_user_children}"
        ;;
esac
#db0:key
        elif [[ \$# == 2 ]];then
case \$2 in
  keys)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null| /bin/grep -w -w "db0"| /bin/grep -w -w "\$1" | /bin/grep -w -w "keys" | awk -F'=|,' '{print \$2}'\`
            echo \$result 
            ;;
 expires)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null| /bin/grep -w -w "db0"| /bin/grep -w -w "\$1" | /bin/grep -w -w "expires" | awk -F'=|,' '{print \$4}'\`
            echo \$result 
            ;;
 avg_ttl)
        result=\`/usr/local/redis/bin/redis-cli -h \$HOST -p \$PORT -a \$PASSWD info 2>/dev/null|/bin/grep -w -w "db0"| /bin/grep -w -w "\$1" | /bin/grep -w -w "avg_ttl" | awk -F'=|,' '{print \$6}'\`
            echo \$result 
            ;;
          *)
     echo "Usage:\$0{db0 keys|db0 expires|db0 avg_ttl}"
        ;;
esac
fi
EOF
chmod -R 744 /etc/zabbix/externalscripts

#3、启动redis服务及zabbix-agent服务
chmod +s /usr/local/redis/bin/redis-cli 
chown -R zabbix:zabbix /etc/zabbix
systemctl enable zabbix-agent
systemctl restart zabbix-agent.service 

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent
firewall-cmd --permanent --query-port=10050/tcp
firewall-cmd --reload

#服务器测试： /usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k redis.status