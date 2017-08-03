#!py
# vim: set filetype=python:

def run():
    machine = salt['pillar.get']('own_stack_cmd:machine')

    config = {}

    config['cloud_created_{}'.format(machine['name'])] = {
        'cloud.profile': [
            {'name': machine['name']},
            {'profile': machine['profile_name']},
        ] + [dict([(k, v)]) for k, v in machine['profile_overrides'].iteritems()]
    }

    return config
