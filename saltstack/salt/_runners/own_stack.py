from salt.exceptions import SaltInvocationError, SaltRunnerError, SaltException
import logging
import salt.client
import salt.cloud
import salt.runner
import salt.config
import salt.wheel
import salt.utils
import os.path
import time
import re
import itertools
import copy

opts = salt.config.master_config('/etc/salt/master')
log = logging.getLogger(__name__)
cloud_config = salt.config.cloud_config('/etc/salt/cloud')

def _parse_scale_args(kwargs, current_by_profile):
    # Keep validated scaling up/down numbers in this dictionary
    safe_nums = {}
    scaling_num_rgx = re.compile('^(\+|-)?([0-9]+)$')
    for profile, scaling_type in kwargs['profiles'].iteritems():
        # Make sure that arguments are valid. We don't want to stop 3 machines
        # if there are only 2 started.
        if profile not in current_by_profile:
            current_by_profile[profile] = []
        match = scaling_num_rgx.search(str(scaling_type))
        if match is None:
            raise SaltInvocationError('The values in the "profiles" dictionary'
            ' must be valid scaling numbers')
        sign, num = match.groups()[0:2]
        if sign == '+':
            try:
                num = int(num)
            except ValueError:
                raise SaltInvocationError('The values in the "profiles" dictionary'
                ' must be valid scaling numbers')
        elif sign == '-':
            try:
                num = -int(num)
            except ValueError:
                raise SaltInvocationError('The values in the "profiles" dictionary'
                ' must be valid scaling numbers')
            if len(current_by_profile[profile]) + num < 0:
                num = -len(current_by_profile[profile])
        else:
            try:
                num = int(num)
            except ValueError:
                raise SaltInvocationError('The values in the "profiles" dictionary'
                ' must be valid scaling numbers')
            num = num - len(current_by_profile[profile])
        safe_nums[profile] = num
    return safe_nums

def scale(outputter=None, display_progress=False, **kwargs):
    '''
    Helper to create or destroy multiple machines at once.

    CLI Example:

    salt-run ownstack.scale profiles='{"web":"+3"}'

    This command starts 3 more machines having the cloud profile web.

    salt-run ownstack.scale profiles='{"web":"+3", "jobs":"-2"}'

    This command starts 3 more machines having the cloud profile web and
    stops 2 machines having the cloud profile jobs.

    You can specify the exact number of machines that must be up.

    salt-run ownstack.scale profiles='{"web":"3", "jobs":"2"}'

    This command ensures that only 3 web machines and 2 jobs machines are up.
    It will start new machines and stop existing machines.
    The command will also run the deploy task on all new web and jobs machines
    and will remove all stopped web machines from the balancer.

    Notice:
    Keys in the profiles dictionary must be profile names specified in /etc/salt/cloud.profiles.d/*
    '''
    if 'profiles' not in kwargs or not isinstance(kwargs['profiles'], dict):
        raise SaltInvocationError('Must specify a "profiles" argument as a dictionary')
    current_by_profile = {}
    profiles_by_name = _up_profiles()
    for minion, profile in profiles_by_name.iteritems():
        if profile not in current_by_profile:
            current_by_profile[profile] = []
        current_by_profile[profile].append(minion)
    for profile, minions in current_by_profile.iteritems():
        current_by_profile[profile] = sorted(minions)
    safe_nums = _parse_scale_args(kwargs, current_by_profile)
    to_create_list = []
    to_destroy_list = []

    for profile, num in safe_nums.iteritems():
        if num > 0:
            to_create_list += _gen_cloud_names(profile + '-', num, profiles_by_name.keys())
        elif num < 0:
            destroy_names = machines_to_stop(profile, abs(num), profiles_by_name.keys())
            to_destroy_list += destroy_names

    log.debug('Machines to create: ' + str(to_create_list))
    log.debug('Machines to destroy: ' + str(to_destroy_list))

    runner_client = salt.runner.RunnerClient(__opts__)
    runner_client.cmd('state.orchestrate', ['orch.scale'],
            kwarg = {'pillar': {'own_stack_cmd': {'machines_to_start': to_create_list, 'machines_to_stop': to_destroy_list}}})

def _up_profiles():
    '''
    Get all connected minion along with their cloud profile
    '''
    client = salt.client.LocalClient(__opts__['conf_file'])
    minions = client.cmd('*', 'grains.get', ['profile'], timeout=2)
    return minions

_machine_num_rgx = re.compile('^[a-zA-Z0-9\-]+-([0-9]+)$')

def _machine_has_profile(name, profile):
    '''
    Check if the machine name matches the cloud profile.

    Machine are numbered using the format <profile_name>-<number>.
    '''
    try:
        if name.startswith(profile) and int(name[len(profile):]):
            return True
    except ValueError:
        pass
    return False

def machines_to_stop(prefix, count, minions):
    '''
    Returns a list of machines to stop.

    Typically sorts the machines by name and then picks the ones at the end.
    We name machines using a prefix and an increasing number and we stop the
    ones having the highest numbers.
    '''
    names = sorted([name for name in minions if _machine_has_profile(name, prefix)], None, None, True)
    assert(len(names) >= count)
    return names[:count]

def _gen_cloud_names(prefix, count, minions):
    '''
    Generates 'count' names for a cloud machine given a prefix.
    '''
    num = av_name_numbers(prefix, count, minions)
    return [prefix + str(i) for i in num]

def _machine_number(name, prefix):
    return int(name[len(prefix):])

def av_name_numbers(prefix, count, minions):
    '''
    Computes a list of available trailing numbers used to uniquely name new cloud machines.
    '''
    if count <= 0:
        return []
    nums = []
    taken = sorted([_machine_number(name, prefix) for name in minions if _machine_has_profile(name, prefix)])
    prev = 0
    for i, num in enumerate(taken):
        if len(nums) >= count:
            break
        prev = taken[i - 1] + 1 if i > 0 else 1
        nums += range(prev, num)
    if len(nums) < count:
        nums += range(prev + 1, count - len(nums) + prev + 1)
    assert(len(nums) >= count)
    return nums[:count]

def _color_abbr(color):
    if color == 'blue':
        return 'b'
    if color == 'green':
        return 'g'
    raise ValueError('Invalid color ' + str(color))

def _default_color():
    return 'blue'

def _other_color(color):
    if color == 'blue':
        return 'green'
    if color == 'green':
        return 'blue'
    raise ValueError('Invalid color ' + str(color))

def _clone_name(name, color):
    '''
    Computes the name of a cloned machine with a different color
    '''
    if name[-1] in [_color_abbr('blue'), _color_abbr('green')]:
        return name[:-1] + _color_abbr(color)
    return name + color_abbr(color)

def _cloud_machine(name, provider_name, profile_name, profile_overrides = None, apps = None):
    return {
        'name': name,
        'profile_name': profile_name,
        'provider_name': provider_name,
        'profile_overrides': profile_overrides,
        'apps': apps
    }

def _cloud_provider(profile_name):
    return cloud_config['profiles'][profile_name]['provider']

def _cloud_driver(provider_name):
    return cloud_config['providers'][provider_name].values()[0]['driver']

def _cloud_roles(profile_name):
    return cloud_config['profiles'][profile_name]['minion']['grains']['roles']

def _profile_apps(roles, pillar_apps):
    return list(set(a['name'] for a in pillar_apps.values()) & set(roles))

def _clone_profiles(machines, color, apps):
    '''
    Computes a list of new machines to start for blue-green deployment.
    All machines marked with 'prev_color' are cloned and marked with 'color'.

    Return a list of dicts instantiated by _cloud_machine
    '''
    clones = []
    for name, m in machines.iteritems():
        if m['profile'] not in cloud_config['profiles']:
            #TODO raise ownstack exceptions
            raise SaltException('Profile {} is not configured'.format(m['profile']))
        provider = _cloud_provider(m['profile'])
        log.debug(cloud_config)
        vm = {'provider': provider, 'profile': m['profile'], 'driver': _cloud_driver(provider.split(':')[0])}
        clone_cfg = salt.config.get_cloud_config_value('minion', vm, cloud_config, {}, True)
        clone_cfg = copy.deepcopy(clone_cfg)
        del clone_cfg['master']
        if 'grains' not in clone_cfg:
            clone_cfg['grains'] = {}
        clone_cfg['grains']['color'] = color
        clones.append(_cloud_machine(_clone_name(name, color),
                                    provider,
                                    m['profile'],
                                    {'minion': clone_cfg},
                                    apps = _profile_apps(_cloud_roles(m['profile']), apps)))
    return clones

def _pillar_tree(name = None):
    client = salt.runner.RunnerClient(__opts__)
    top_pillar = client.cmd('pillar.show_pillar')
    if name is None:
        return top_pillar
    subtree = salt.utils.traverse_dict(top_pillar, name, {})
    return subtree

def _extend_pillar(dest, updt):
    return salt.utils.dictupdate.update(dest, updt, recursive_update = True)

def deploy_blue_green(app_name, app_version, outputter=None, display_progress=False):
    '''
    Blue green deployment for load balanced apps. Deploys application to new machines
    and shuts down old ones.
    Encodes parameters into a dict to pass it to the deploy_blue_green
    orchestration state.
    There are only 2 colors, blue and green. If not all of the active web machines
    are of the same color, then the system is in an inconsistent state and this runner
    errors.
    '''
    client = salt.client.LocalClient(__opts__['conf_file'])
    tgt = 'G@roles:{}'.format(app_name)
    minions = client.cmd(tgt, 'grains.item', ['profile', 'color'], timeout=2, expr_form='compound')
    log.debug('minions: ' + str(minions))
    if not len(minions):
        raise SaltRunnerError('No machines to deploy to')
    unique = set((m['color'] for m in minions.values()))
    if len(unique) > 1:
        raise SaltRunnerError('More than one color active {}'.format(str(unique)))
    active_color = None
    if len(unique) == 1:
        active_color = next(iter(unique))
    if active_color is None or active_color == '':
        active_color = _default_color()
    log.debug('active_color = ' + active_color)
    next_color = _other_color(active_color)
    apps = _pillar_tree('apps')
    to_stop = [_cloud_machine(name, _cloud_provider(v['profile']), v['profile'], apps = _profile_apps(_cloud_roles(v['profile']), apps))
            for name, v in minions.iteritems()]
    to_start = _clone_profiles(minions, next_color, apps)
    log.debug('machines = ' + repr(to_start))
    assert(len(to_start) == len(minions))
    log.debug('apps for orch: ' + str(_extend_pillar(apps, dict([(app_name, {'rev': app_version})]))))
    pillar = {
        'own_stack_cmd': {
            'app_name': app_name,
            'app_version': app_version,
            'color': next_color,
            'prev_color': active_color,
            'machines_to_start': to_start,
            'machines_to_stop': to_stop
        },
        'apps': _extend_pillar(apps, dict([(app_name, {'rev': app_version})]))
    }
    log.debug('pillar for deploy_blue_green: ' + str(pillar))
    runner_client = salt.runner.RunnerClient(__opts__)
    runner_client.cmd('state.orchestrate', ['orch.deploy_blue_green'], kwarg={'pillar': pillar})

def maintenance(app_name, outputter = None, display_progress = None):
    runner_client = salt.runner.RunnerClient(__opts__)
    runner_client.cmd('state.orchestrate', ['orch.maintenance'], kwarg={'pillar': {
        'own_stack_cmd': {
            'app_name': app_name
        }
    }})

def test():
    apps = _pillar_tree('apps')
    apps = _extend_pillar(apps, dict([('web', {'rev': 'dev', 'gigelu': '22'})]))
    runner_client = salt.runner.RunnerClient(__opts__)
    pillar = {
        'apps': apps
    }
    runner_client.cmd('state.orchestrate', ['orch.test'], kwarg={'pillar': pillar})
