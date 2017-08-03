{% from 'web/vars.sls' import app %}

{{ app.name }}_stopped:
  service.dead:
    - name: pm2_{{ app.name }}
    - enable: False
