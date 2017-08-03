{%- from 'vars.sls' import monitor_ip, is_monitor -%}

ganglia client:
  pkg.installed:
    - pkgs:
      - ganglia-monitor

/etc/ganglia/gmond.conf:
  file.managed:
    - source: salt://ganglia/files/gmond.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      server: {{ monitor_ip }}
      is_monitor: {{ is_monitor }}

ganglia monitor service:
  service.running:
    - name: ganglia-monitor
    - watch:
      - /etc/ganglia/gmond.conf
