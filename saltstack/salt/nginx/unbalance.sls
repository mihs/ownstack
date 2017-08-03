{% set servers = salt['pillar.get']('own_stack_cmd:machines_to_stop') %}

{% for server_ip in servers %}
nginx_upstream_{{ server_ip }}:
  own_stack.nginx_upstream_server_disabled:
    - host: {{ server_ip }}
{% endfor %}
