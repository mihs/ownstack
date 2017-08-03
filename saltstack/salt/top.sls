base:
  '*':
    - common
    - rsyslog
  'G@roles:monitored':
    - ganglia.client
  'G@roles:web':
    - pm2
  'G@roles:jobs':
    - pm2
  'G@roles:balancer':
    - nginx
  'G@roles:kibana':
    - kibana
  'G@roles:ganglia':
    - ganglia.server
  'G@roles:elasticsearch':
    - elasticsearch
  'G@roles:monitor':
    - logstash
