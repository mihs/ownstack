base:
  '*':
    - default
    - app.web
    - app.jobs
  'G@roles:monitor':
    - monitor
  'G@roles:web':
    - web
  'G@roles:balancer':
    - app.web
  'G@roles:elasticsearch':
    - es
  'G@roles:kibana':
    - kibana
  'G@roles:ganglia':
    - ganglia
