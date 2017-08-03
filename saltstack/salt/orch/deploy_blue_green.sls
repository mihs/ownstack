#!py
# vim: set filetype=python:

def run():

    config = {}

    # highstate with salt.function
    # https://github.com/saltstack/salt/issues/26448
    config['requisites'] = {
        'salt.function': [
            {'name': 'state.highstate'},
            {'tgt': '*'}
        ]
    }

    config['start_machines'] = {
        'salt.runner': [
            {'name': 'state.orchestrate'},
            {'mods': 'orch.start'},
            {'pillar': {
                'own_stack_cmd': __salt__['pillar.get']('own_stack_cmd'),
                'apps': __salt__['pillar.get']('apps')
            }},
            {'require': ['requisites']}
        ]
    }

    config['balancer'] = {
        'salt.runner': [
            {'name': 'state.orchestrate'},
            {'mods': 'orch.balance'},
            {'pillar': {'own_stack_cmd': __salt__['pillar.get']('own_stack_cmd')}},
            {'require': ['start_machines']}
        ]
    }

    config['stop_machines'] = {
        'salt.runner': [
            {'name': 'state.orchestrate'},
            {'mods': 'orch.stop'},
            {'pillar': {'own_stack_cmd': __salt__['pillar.get']('own_stack_cmd')}},
            {'require': ['balancer']}
        ]
    }

    config['maintenance'] = {
        'salt.runner': [
            {'name': 'state.orchestrate'},
            {'mods': 'orch.maintenance'},
            {'onfail': ['start_machines', 'balancer']}
        ]
    }

    return config
