sdfdssdg:
  cmd.run:
{% if 2 %}
  {% for i in [2, 3, 4] %}
    - {{ i }}
  {% endfor %}
{% endif %}
