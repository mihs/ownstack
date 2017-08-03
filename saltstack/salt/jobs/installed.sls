include:
  - jobs.fetched

{% from 'jobs/vars.sls' import app, app_directory, pm2_process_file %}

{{ app.name }}_installed:
  cmd.run:
    - name: 'npm install'
    - env:
      - "{{ salt['own_stack.env_str_from_obj'](app.env) }}"
    - cwd: {{ app_directory + '/current' }}
    - runas: {{ app.run_as_user }}
    - require:
      - sls: jobs.fetched
