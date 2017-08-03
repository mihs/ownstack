#!py
# vim: set filetype=python:

def run():
    machines_to_stop = __salt__['pillar.get']('own_stack_cmd:machines_to_stop')

    config = {}

    app_roles = set([app for m in machines_to_stop for app in m['apps']])

    for role in app_roles:
        config['app_stopped_{}'.format(role)] = {
            'salt.state': [
                {'tgt': ','.join([m['name'] for m in machines_to_stop])},
                {'tgt_type': 'list'},
                {'sls': '{}.stopped'.format(role)},
                {'pillar': {'apps': __salt__['pillar.get']('apps')}},
            ]
        }

    for m in machines_to_stop:
        config['destroy_{}'.format(m['name'])] = {
            'salt.state': [
                {'tgt': 'saltmaster'},
                {'sls': 'orch.cloud_destroyed'},
                {'pillar': {'own_stack_cmd': {'machine': m}}},
                {'require': ['app_stopped_{}'.format(role) for role in app_roles]}
            ]
        }

    return config
