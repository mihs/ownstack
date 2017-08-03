rsyslog:
  pkg.installed

/etc/rsyslog.d:
  file.directory:
    - user: root
    - group: root
    - mode: 755

/etc/rsyslog.conf:
  file.managed:
    - source: salt://rsyslog/files/rsyslog.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja

/etc/rsyslog.d/10-centrallog.conf:
  file.managed:
    - source: salt://rsyslog/files/10-centrallog.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      logstash_ip: {{ salt['own_stack.logstash_ip']() }}
      monitor_ip: {{ salt['own_stack.monitor_ip']() }}
      is_monitor: {{ salt['own_stack.has_role']('monitor') }}

/etc/rsyslog.d/01-json-template.conf:
  file.managed:
    - source: salt://rsyslog/files/01-json-template.conf
    - user: root
    - group: root
    - mode: 644

rsyslog service:
    service.running:
      - name: rsyslog
      - watch:
        - file: /etc/rsyslog.d/10-centrallog.conf
        - file: /etc/rsyslog.d/01-json-template.conf
