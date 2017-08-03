include:
  - java

{% set version = salt['pillar.get']('elasticsearch:version', '') %}
{% set should_install = salt['own_stack.should_install']('elasticsearch') %}

es_repo:
  pkgrepo.managed:
    - name: deb https://packages.elastic.co/elasticsearch/2.x/debian stable main
    - file: /etc/apt/sources.list.d/elasticsearch-2.x.list
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch
# The following does not work for some reason, the next rule is a workaround
{% if should_install or version == 'latest' %}
    - refresh_db: True
{% endif %}

{% if should_install or version == 'latest' %}
es_repo_update:
  module.run:
    - name: pkg.refresh_db
    - require:
      - es_repo
    - watch:
      - es_repo
{% endif %}

es_installed:
  pkg.installed:
    - name: 'elasticsearch'
    - version: {{ version }}

/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://elasticsearch/files/elasticsearch.yml
    - user: root
    - group: elasticsearch
    - mode: 750
    - template: jinja
    - context:
      es_mode: {{ salt['pillar.get']('elasticsearch:mode', '') }}

es_service:
  service.running:
    - name: elasticsearch
    - enable: True
    - require:
      - sls: java.installed
      - es_installed
    - watch:
      - /etc/elasticsearch/elasticsearch.yml
