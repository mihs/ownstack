{% set app = salt['pillar.get']('apps:jobs') %}
{% set app_directory = '/home/' + app.run_as_user + '/apps/' + app.name %}
{% set pm2_process_file = app_directory + '/current/process_jobs.yml'  %}
