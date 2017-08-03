include:
{% if not salt['own_stack.has_role']('elasticsearch') %}
  - elasticsearch
{% endif %}
  - .installed
