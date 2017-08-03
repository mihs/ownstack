include:
  - jobs.fetched
  - jobs.installed

{% from 'jobs/vars.sls' import app, app_directory, pm2_process_file %}
{% set user = app.run_as_user %}

{{ user }}_pm2-syslog:
  cmd.run:
    - name: 'pm2 install pm2-syslog'
    - unless: 'pm2 list | grep pm2-syslog | grep online'
    - runas: {{ user }}
    - shell: '/bin/bash'
    - require:
      - pm2

{{ pm2_process_file }}:
  file.managed:
    - source: salt://jobs/files/process.yml
    - user: {{ app.run_as_user }}
    - mode: 644
    - template: jinja
    - context:
      app_name: {{ app.name }}
      script_env: {{ app.env|yaml }}
    - require:
      - sls: pm2.installed
      - sls: jobs.fetched
      - sls: jobs.installed

/etc/systemd/system/pm2_{{ app.name }}.service:
  file.managed:
    - source: salt://jobs/files/pm2.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      user: {{ app.run_as_user }}
      app_directory: {{ app_directory }}
      app_name: {{ app.name }}

{{ app.name }}_running:
  service.running:
    - name: pm2_{{ app.name }}
    - enable: True
    - watch:
      - /etc/systemd/system/pm2_{{ app.name }}.service
      - {{ app.name }}_fetched
      - {{ app.name }}_installed
    - require:
      - sls: pm2.installed
      - sls: jobs.fetched
      - sls: jobs.installed
      - {{ pm2_process_file }}