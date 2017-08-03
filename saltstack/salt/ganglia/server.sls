{%- from 'vars.sls' import monitor_ip, is_monitor -%}

apache:
  pkg.installed:
    - pkgs:
      - apache2
      - apache2-utils

ganglia_server:
  pkg.installed:
    - pkgs:
      - ganglia-monitor
      - rrdtool
      - gmetad
      - ganglia-webfrontend
    - require:
      - apache

/etc/ganglia/gmetad.conf:
  file.managed:
    - source: salt://ganglia/files/gmetad.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      server: {{ monitor_ip }}
      is_monitor: {{ is_monitor }}

/etc/apache2/sites-available/ganglia.conf:
  file.managed:
    - source: salt://ganglia/files/apache.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      domain: {{ salt['pillar.get']('domain') }}

default apache site disabled:
  apache_site.disabled:
    - name: 000-default
    - require:
      - apache

ganglia apache site:
  apache_site.enabled:
    - name: ganglia
    - require:
      - apache

apache service:
  service.running:
    - name: apache2
    - require:
      - apache
    - watch:
      - default apache site disabled
      - ganglia apache site
      - /etc/apache2/sites-available/ganglia.conf

ganglia service:
  service.running:
    - name: gmetad
    - require:
      - ganglia_server
    - watch:
      - /etc/ganglia/gmetad.conf
