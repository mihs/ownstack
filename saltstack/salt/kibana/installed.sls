include:
  - java

{% set version = salt['pillar.get']('kibana:version', '') %}
{% set should_install = salt['own_stack.should_install']('kibana') %}

kibana_repo:
  pkgrepo.managed:
    - name: deb https://packages.elastic.co/kibana/4.6/debian stable main
    - file: /etc/apt/sources.list.d/kibana.list
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch
# The following does not work for some reason, the next rule is a workaround
{% if should_install or version == 'latest' %}
    - refresh_db: True
{% endif %}

{% if should_install or version == 'latest' %}
kibana_repo_update:
  module.run:
    - name: pkg.refresh_db
    - require:
      - kibana_repo
    - watch:
      - kibana_repo
{% endif %}

kibana_installed:
  pkg.installed:
    - name: 'kibana'
    - version: {{ version }}

/opt/kibana/config/kibana.yml:
  file.managed:
    - source: salt://kibana/files/kibana.yml
    - user: root
    - group: root
    - mode: 664
    - template: jinja
    - context:
      es_server: {{ salt['own_stack.local_ipv4']() }}

kibana_service:
  service.running:
    - name: kibana
    - enable: True
    - require:
      - sls: java.installed
{% if should_install %}
      - kibana_installed
{% endif %}
    - watch:
      - /opt/kibana/config/kibana.yml
