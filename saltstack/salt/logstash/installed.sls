include:
  - java

{% set version = salt['pillar.get']('logstash:pkg_version', '') %}
{% set should_install = salt['own_stack.should_install']('logstash') %}

logstash_repo:
  pkgrepo.managed:
    - name: deb https://packages.elastic.co/logstash/2.4/debian stable main
    - file: /etc/apt/sources.list.d/logstash-2.4.list
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch
# The following does not work for some reason, the next rule is a workaround
{% if should_install or version == 'latest' %}
    - refresh_db: True
{% endif %}

{% if should_install or version == 'latest' %}
logstash_repo_update:
  module.run:
    - name: pkg.refresh_db
    - require:
      - logstash_repo
    - watch:
      - logstash_repo
{% endif %}

logstash_installed:
  pkg.installed:
    - name: 'logstash'
    - version: {{ version }}

/etc/logstash/es_template_logs.json:
  file.managed:
    - source: salt://logstash/files/es_template_logs.json
    - user: logstash
    - group: logstash
    - mode: 640

/etc/logstash/conf.d/logs.conf:
  file.managed:
    - source: salt://logstash/files/logs.conf
    - user: logstash
    - group: logstash
    - mode: 640
    - template: jinja
    - context:
      es_api_port: {{ salt['pillar.get']('elasticsearch:api_port', 9200) }}
      es_hosts: {{ salt['own_stack.elasticsearch_ips']() }}

logstash_service:
  service.running:
    - name: logstash
    - enable: True
    - watch:
      - /etc/logstash/conf.d/logs.conf
    - reload: True
    - require:
      - sls: java.installed
{% if should_install %}
      - logstash_installed
{% endif %}
      - /etc/logstash/conf.d/logs.conf
