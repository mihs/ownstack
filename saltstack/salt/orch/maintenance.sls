nginx maintenance page:
  salt.state:
    - tgt: 'roles:balancer'
    - tgt_type: 'grain'
    - sls: nginx.maintenance
