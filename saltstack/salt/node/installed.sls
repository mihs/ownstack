{% set node_version = salt['pillar.get']('node:version')  %}
{% set node_pkg_version = salt['pillar.get']('node:pkg_version')  %}

# noderepo:
#   cmd.run:
#     - name: 'curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -'
#     - shell: /bin/bash
#     - unless: '[[  `node -v` =~ ^"v{{ node_version }}" ]]'

nodejs:
  pkg.installed:
    {% if node_pkg_version != None %}
    - sources:
      - nodejs: {{ salt['pillar.get']('node:pkg_location') }}
    - version: {{ node_pkg_version }}
    {% endif %}
