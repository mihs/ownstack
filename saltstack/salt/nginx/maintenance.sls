{% set domain = salt['pillar.get']('domain') %}

/var/www/{{ domain }}/maintenance:
  file.recurse:
    - source: salt://nginx/files/maintenance
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - clean: True
    - include_empty: True
    - force_symlinks: True
    - keep_symlinks: True
    - makedirs: True

/etc/nginx/sites-available/maintenance:
  file.managed:
    - source: salt://nginx/files/site.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      domain: {{ domain }}
      maintenance: True

disable sites:
  file.directory:
    - name: /etc/nginx/sites-enabled
    - clean: True

/etc/nginx/sites-enabled/maintenance:
  file.symlink:
    - target: /etc/nginx/sites-available/maintenance
    - force: True
    - user: root
    - group: root
    - mode: 644
    - require:
      - disable sites

reload-nginx:
  module.run:
    - name: nginx.signal
    - signal: reload
    - onchanges:
      - /etc/nginx/sites-available/maintenance
