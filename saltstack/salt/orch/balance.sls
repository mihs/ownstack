#!py
# vim: set filetype=python:

def run():
    color = __salt__['pillar.get']('own_stack_cmd:color')
    prev_color = __salt__['pillar.get']('own_stack_cmd:prev_color')
    machines_to_start = __salt__['pillar.get']('own_stack_cmd:machines_to_start')
    machines_to_stop = __salt__['pillar.get']('own_stack_cmd:machines_to_stop')
    role = __salt__['pillar.get']('own_stack_cmd:app_name')

    config = {}

    config['nginx_update'] = {
        'salt.state': [
            {'tgt': 'roles:balancer'},
            {'tgt_type': 'grain'},
            {'sls': 'nginx.webservers'},
            {'pillar': {'own_stack_cmd': {
                'balancer': {
                    'enabled': {
                        'server_names': [m['name'] for m in machines_to_start if m.get('balancer', False)]
                    },
                    'disabled': {
                        'server_names': [m['name'] for m in machines_to_stop if m.get('balancer', False)]
                    }
                },
                'color': color,
                'prev_color': prev_color,
                'app_name': role
            }}}
        ]
    }

    return config
