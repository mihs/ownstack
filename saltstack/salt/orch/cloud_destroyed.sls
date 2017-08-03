#!py
# vim: set filetype=python:

def run():
    machine = salt['pillar.get']('own_stack_cmd:machine')

    config = {}

    config['cloud_destroyed_{}'.format(machine['name'])] = {
        'cloud.absent': [
            {'name': machine['name']}
        ]
    }

    return config
