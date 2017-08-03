{%- from 'jobs/vars.sls' import app, app_directory, pm2_process_file -%}

{{ app_directory }}:
  file.directory:
    - user: {{ app.run_as_user }}
    - group: {{ app.run_as_user }}
    - makedirs: True

{% if app.source == 'git' %}

{{ app.name }}_fetched:
  git.latest:
    - name: {{ app.url }}
    - rev: {{ app.rev }}
    - target: {{ app_directory + '/releases/tmp' }}
    - remote: origin
    - user: {{ app.run_as_user }}
    - force_clone: True
    - force_checkout: True
    - force_fetch: True
    - force_reset: True
    - submodules: True
    - bare: False
    # - identity: salt://keys/app_git.rsa

{% elif app.source == 'salt' %}

{{ app.name }}_clean_directory:
  file.absent:
    - name: {{ app_directory }}/releases/{{ app.rev }}

{{ app.name }}_fetched:
  file.recurse:
    - name: {{ app_directory + '/releases/tmp' }}
    - source: {{ app.url }}
    - user: {{ app.run_as_user }}
    - group: {{ app.run_as_user }}
    - dir_mode: 755
    - file_mode: 644
    - clean: True
    - include_empty: True
    - force_symlinks: True
    - keep_symlinks: True
    - makedirs: True

{% endif %}

{{ app.name }}_set_current:
{% if app.source == 'git' %}
  cmd.run:
    - name: 'cd releases/tmp && rev=`git rev-parse {{ app.rev }}` && cd .. && if [[ -d $rev ]]; then rm -rf $rev; fi && mv -f -T tmp $rev && cd .. && ln -sf -T releases/$rev current && cd releases && ls -1c | tail -n +6 | xargs rm -rf'
    - cwd: {{ app_directory }}
    - runas: {{ app.run_as_user }}
    - shell: '/bin/bash'
    - require:
      - {{ app.name }}_fetched
    - onchanges:
      - {{ app.name }}_fetched
{% elif app.source == 'salt' %}
  cmd.run:
    - name: 'cd releases/tmp && rev={{ app.rev }} && cd .. && if [[ -d $rev ]]; then rm -rf $rev; fi && mv -f -T tmp $rev && cd .. && ln -sf -T releases/$rev current && cd releases && ls -1c | tail -n +6 | xargs rm -rf'
    - cwd: {{ app_directory }}
    - runas: {{ app.run_as_user }}
    - shell: '/bin/bash'
    - require:
      - {{ app.name }}_fetched
    - onchanges:
      - {{ app.name }}_fetched
{% endif %}
