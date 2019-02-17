#!/bin/bash
#http://mirrors.aliyun.com/zabbix/zabbix/3.4/
#1、安装zabbix-agent客户端
cd /usr/local/src/lnmp/zabbix/mongodb-zabbix
yum -y install zabbix-agent-3.4.15-1.el7.x86_64.rpm

#2、配置zabbix-agent监听（需要修改允许监听的服务器地址）
echo 'LogFile=/var/log/zabbix/zabbix_agentd_elasticsearch.log
#zabbix server的ip地址，多个ip使用逗号分隔
Server=192.168.8.50
ServerActive=192.168.8.50
#zabbix agent的ip地址
Hostname=192.168.8.51
ListenPort=10050
HostMetadataItem=system.uname
# Return statistics
UserParameter=elasticsearchd.status[*],/etc/zabbix/externalscripts/elasticsearch.py $1 $2
' > /etc/zabbix/zabbix_agentd.d/zabbix_agentd_elasticsearch.conf 

#3、配置zabbix-agent监听py脚本（需要修改主机客户端地址）【脚本最好复制，cat写入不了】
mkdir -pv /etc/zabbix/externalscripts
yum install -y python34
cat > /etc/zabbix/externalscripts/elasticsearch.py <<EOF
#!/usr/bin/env python3
##################################################
# Description：zabbix 通过 status 模块监控 elasticsearch
# Note：Zabbix 3.4
##################################################
try:
	import time, json
	import os, sys, errno
	import logging, logging.handlers
	#import configparser
	from optparse import OptionParser, OptionGroup
	#from urllib import 
	import urllib.request
except ImportError as err:
	print("Error: %s" %(err))

class Elasticsearch():
	stats = {
		    'cluster': 'http://localhost:9200/_cluster/stats',
		    'nodes'  : 'http://localhost:9200/_nodes/stats',
		    'indices': 'http://localhost:9200/_stats',
		    'health' : 'http://localhost:9200/_cluster/health'
		}

	def __init__(self):
		self.ttl = 60
		pass

	def lock(self,name):
		try:
			fd = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL)
			os.close(fd)
			return True
		except OSError as e:
			if e.errno == errno.EEXIST:
				return False
			raise
	def expire(self,key, ttl):
		if not os.path.exists(key):
			return True
		elif (time.time() - os.path.getmtime(key)) > ttl:
			return True
		else:
			return False
			#return self.lock(key+".lock")

	def open(self, module):
		text=""
		json_obj = None
		cache = '/tmp/elastizabbix-{0}.json'.format(module)
		if self.expire(cache, self.ttl):
			text = urllib.request.urlopen(self.stats[module]).read().decode("utf-8")
			with open(cache, 'w') as f: f.write(text)
			json_obj = json.loads(text)
		else:
			json_obj =  json.load(open(cache))
	
		return json_obj

	def get(self, module, keyworld):
		json_obj = self.open(module);
		keys = []
		for i in keyworld.split('.'):
			keys.append(i)
			key = '.'.join(keys)
			if key in json_obj:
				json_obj = json_obj.get(key)
			keys = []
		return json_obj

	def discover(self,module):
		d= {'data': []}
		if module == 'nodes':	
			for k,v in self.get('nodes', 'nodes').items():
				d['data'].append({'{#NAME}': v['name'], '{#NODE}': k})

		if module == "indices":
			for k,v in self.get('indices', 'indices').items():
				d['data'].append({'{#NAME}': k})
		return json.dumps(d)

	
	def main(self):
		parser = OptionParser(usage='usage: %prog <module> <keyword>', version="%prog 1.0.0", description='Elasticsearch for Zabbix')
		(options, args) = parser.parse_args()

		if not len(args) == 2:
			parser.print_help()
			sys.exit(1)
		
		module = args[0]
		keyword = args[1]

		if module in self.stats.keys():
			print(self.get(module, keyword))
		elif module == "discover":
			print(self.discover(keyword))
		else:
			parser.print_help()
	
if __name__ == '__main__':
	try:
		elastic = Elasticsearch()
		elastic.main()
	except KeyboardInterrupt:
		print ("Crtl+C Pressed. Shutting down.")
EOF 
chmod -R 744 /etc/zabbix/externalscripts

#3、启动elasticsearch服务及zabbix-agent服务
chmod +s /etc/zabbix/externalscripts/elasticsearch.py
chown -R zabbix:zabbix /etc/zabbix
systemctl enable zabbix-agent
systemctl restart zabbix-agent.service 

firewall-cmd --permanent --zone=public --add-port=10050/tcp --permanent
firewall-cmd --permanent --query-port=10050/tcp
firewall-cmd --reload

#服务器测试：/usr/local/zabbix/bin/zabbix_get -s 192.168.8.51 -k 'elasticsearch.status[indices,_all.total.flush.total_time_in_millis]'
