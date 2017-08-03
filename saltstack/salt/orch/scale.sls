#!py
# vim: set filetype=python:

def run():

    machines_to_start = __salt__['pillar.get']('own_stack_cmd:machines_to_start')
    machines_to_stop = __salt__['pillar.get']('own_stack_cmd:machines_to_stop')

    config = {}

    config['requisites'] = {
        'salt.state': [
            {'tgt': '*'},
            {'highstate': True}
        ]
    }

    for m in machines_to_start:
        config['start_machines_{}'.format(m['name'])] = {
            'salt.runner': [
                {'name': 'state.orchestrate'},
                {'mods': 'orch.start'},
                {'pillar': {'own_stack_cmd': __salt__['pillar.get']('own_stack_cmd')}},
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

    return config
