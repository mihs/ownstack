{% set is_monitor = salt['own_stack.has_role']('monitor') %}
{% set monitor_ip = salt['own_stack.monitor_ip']()  %}
