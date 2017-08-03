#!py
# vim: set filetype=python:

def run():
    machines_to_start = __salt__['pillar.get']('own_stack_cmd:machines_to_start')

    config = {}

    for m in machines_to_start:
        config['create_{}'.format(m['name'])] = {
            'salt.state': [
                {'tgt': 'saltmaster'},
                {'sls': 'orch.cloud_created'},
                {'pillar': {'own_stack_cmd': {'machine': m}}}
            ]
        }

    # config['sync_all'] = {
    #     'salt.function': [
    #         {'name': 'saltutil.sync_all'},
    #         {'tgt': ','.join([m['name'] for m in machines_to_start])},
    #         {'tgt_type': 'list'},
    #         {'require': ['create_{}'.format(m['name']) for m in machines_to_start]}
    #     ]
    # }

    # highstate with salt.function
    # https://github.com/saltstack/salt/issues/26448
    config['highstate'] = {
        'salt.function': [
            {'name': 'state.highstate'},
            {'tgt': ','.join([m['name'] for m in machines_to_start])},
            {'tgt_type': 'list'},
            # {'pillar': {'apps': __salt__['pillar.get']('apps')}},
            # {'require': ['sync_all']}
            {'require': ['create_{}'.format(m['name']) for m in machines_to_start]}
        ]
    }

    config['refresh_mine'] = {
        'salt.function': [
            {'name': 'mine.update'},
            {'tgt': ','.join([m['name'] for m in machines_to_start])},
            {'tgt_type': 'list'},
            {'require': ['highstate'] + ['create_{}'.format(m['name']) for m in machines_to_start]}
        ]
    }

    app_roles = set([app for m in machines_to_start for app in m['apps']])

    for role in app_roles:
        config['app_started_{}'.format(role)] = {
            'salt.state': [
                {'tgt': ','.join([m['name'] for m in machines_to_start])},
                {'tgt_type': 'compound'},
                {'sls': '{}.started'.format(role)},
                {'pillar': {'apps': __salt__['pillar.get']('apps')}},
                {'require': ['refresh_mine'] + ['create_{}'.format(m['name']) for m in machines_to_start]}
            ]
        }

    return config
