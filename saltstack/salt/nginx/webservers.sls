{% set domain = salt['pillar.get']('domain') %}
{% set servers_enabled = salt['own_stack.nginx_web_servers']('enabled') %}
{% set servers_disabled = salt['own_stack.nginx_web_servers']('disabled') %}
{% set app_name = salt['pillar.get']('own_stack_cmd:app_name') %}

/etc/nginx/sites-available/app-{{app_name}}:
  file.managed:
    - source: salt://nginx/files/site.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      domain: {{ domain }}

/etc/nginx/sites-enabled/app-{{app_name}}:
  file.symlink:
    - target: /etc/nginx/sites-available/app-{{app_name}}
    - force: True
    - user: root
    - group: root
    - mode: 644

{% if servers_enabled %}
  {% for server_ip in servers_enabled %}
nginx_upstream_enabled_{{ server_ip }}:
  own_stack.nginx_upstream_server_enabled:
    - host: {{ server_ip }}
    - app_name: {{ app_name }}
  {% endfor %}
{% endif %}

{% if servers_disabled %}
  {% for server_ip in servers_disabled %}
nginx_upstream_disabled_{{ server_ip }}:
  own_stack.nginx_upstream_server_disabled:
    - host: {{ server_ip }}
    - app_name: {{ app_name }}
  {% endfor %}
{% endif %}

{% if servers_enabled or servers_disabled %}
reload-nginx:
  module.run:
    - name: nginx.signal
    - signal: reload
    - require:
{% if servers_enabled %}
  {% for server_ip in servers_enabled %}
      - nginx_upstream_enabled_{{ server_ip }}
  {% endfor %}
{% endif %}
{% if servers_disabled %}
  {% for server_ip in servers_disabled %}
      - nginx_upstream_disabled_{{ server_ip }}
  {% endfor %}
{% endif %}
{% endif %}
