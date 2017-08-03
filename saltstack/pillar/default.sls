elasticsearch:
  version: 2.4.2
  api_port: 9200
  comm_port: 9300
  cluster: own_stack
  pkg_location: salt://elasticsearch/files/elasticsearch-2.4.2.deb
logstash:
  version: 2.4.0
  pkg_version: 1:2.4.0-1
kibana:
  port: 5601
ganglia:
  cluster: own_stack
  collect_freq: 10
  web:
    port: 80
node:
  version: 6.7.0
  pkg_version: 6.7.0-1nodesource1~jessie1
  pkg_location: salt://node/files/nodejs_6.7.0-1nodesource1~jessie1_amd64.deb
nginx:
  version: 1.10.1-1~jessie
admin_area:
  user: hardtoguessusername
  passwd: 'ScoW0|)03$=8A3.k'
domain: ownstackmonitor.com
admin_emails:
  - admin@example.com
# smtp:
#   host: ''
#   port: 587
#   tls: True
#   username: ''
#   password: ''
#   from: ''
