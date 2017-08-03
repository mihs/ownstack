{% set domain = salt['pillar.get']('domain', '_') %}

nginx_repo:
  pkgrepo.managed:
    - name: deb http://nginx.org/packages/debian/ jessie nginx
    - file: /etc/apt/sources.list.d/nginx.list
    - key_url: http://nginx.org/keys/nginx_signing.key

{% set version = salt['pillar.get']('nginx:version', 'lastest') %}
{% set current_version = salt['pkg.version']('nginx') %}

nginx:
  pkg.installed:
    - version: {{ version }}
{% if salt['own_stack.should_install']('nginx') or version == 'latest' %}
    - refresh: True
{% else %}
    - refresh: False
{% endif %}

apache2-utils:
  pkg.installed

/etc/nginx/sites-available:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/nginx/sites-enabled:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

nginx user:
  user.present:
    - name: www-data

private cert group:
  group.present:
    - name: ssl-cert

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/files/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja

/etc/nginx/cert.conf:
  file.managed:
    - source: salt://nginx/files/cert.conf
    - user: root
    - group: root
    - mode: 644

/etc/ssl/certs:
  file.directory:
    - user: root
    - group: root
    - mode: 755

/etc/ssl/private:
  file.directory:
    - user: root
    - group: root
    - mode: 711

/etc/ssl/certs/ssl-cert-app.pem:
  file.managed:
    - source: salt://nginx/files/cert.pem
    - user: root
    - group: root
    - mode: 644

/etc/ssl/private/ssl-cert-app.key:
  file.managed:
    - source: salt://nginx/files/cert.key
    - user: root
    - group: ssl-cert
    - mode: 640

/etc/nginx/{{ domain }}:
  file.directory:
    - user: www-data
    - group: www-data
    - allow_symlink: True
    - mode: 755

/etc/nginx/{{ domain }}/htpasswd:
  file.managed:
    - user: www-data
    - group: www-data
    - allow_symlink: True
    - mode: 640
    - makedirs: True
    - dir_mode: 755
    - contents: ''
    - replace: False

admin_area user:
  webutil.user_exists:
    - name: {{ salt['pillar.get']('admin_area:user') }}
    - password: {{ salt['pillar.get']('admin_area:passwd') }}
    - htpasswd_file: /etc/nginx/{{ domain }}/htpasswd

/etc/nginx/sites-available/ganglia:
  file.managed:
    - source: salt://nginx/files/ganglia.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      domain: {{ domain }}
      servers:
        - {{ salt['own_stack.ganglia_server_ip']() }}

/etc/nginx/sites-enabled/ganglia:
  file.symlink:
    - target: /etc/nginx/sites-available/ganglia
    - force: True
    - user: root
    - group: root
    - mode: 644

/etc/nginx/sites-available/kibana:
  file.managed:
    - source: salt://nginx/files/kibana.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      domain: {{ domain }}
      servers:
        - {{ salt['own_stack.kibana_ip']() }}

/etc/nginx/sites-enabled/kibana:
  file.symlink:
    - target: /etc/nginx/sites-available/kibana
    - force: True
    - user: root
    - group: root
    - mode: 644

/etc/nginx/sites-enabled/default:
  file.absent

/etc/nginx/sites-available/default:
  file.absent

/etc/nginx/{{ domain }}/servers:
  file.directory:
    - clean: True
    - user: root
    - group: root
    - mode: 755

reload-nginx:
  module.run:
    - name: nginx.signal
    - onchanges:
      - /etc/nginx/sites-available/ganglia
      - /etc/nginx/sites-available/kibana
    - signal: reload
