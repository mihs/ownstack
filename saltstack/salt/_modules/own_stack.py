from salt.exceptions import NotImplemented
import requests
import requests.exceptions
import logging
import salt.config
from salt.exceptions import SaltException
import copy

log = logging.getLogger(__name__)

def env_str_from_obj(obj):
    return ' '.join(('{0}:{1}'.format(k, v) for k, v in obj.iteritems()))

def apps():
    return __salt__['pillar.get']('apps')

def jobs_ips():
    return role_ips('jobs')

def running_web_server_ips(app_name):
    web_role_ips = role_ips(app_name, with_color = True)
    port = __salt__['pillar.get']('apps:{}:env:port'.format(app_name))
    web_test_url = __salt__['pillar.get']('apps:{}:test_url'.format(app_name))
    responding = []
    for ip in web_role_ips:
        try:
            r = requests.get('http://{}:{}{}'.format(ip, port, web_test_url), timeout=5)
            if r.status_code == requests.codes.ok:
                responding.append(ip)
        except requests.exceptions.RequestException:
            pass
    return responding

def elasticsearch_ips():
    return role_ips('elasticsearch')

def hosts_port(hosts, port):
    return ["{0}:{1}".format(host, port) for host in hosts if host]

def role_ips(role, with_color = False):
    target = 'G@roles:' + role
    if with_color:
        color = __salt__['pillar.get']('own_stack_cmd:color')
        if color:
            target = 'G@roles:{} and G@color:{}'.format(role, color)
    return [ips[0] for ips in __salt__['mine.get'](target, 'internal_ip', 'compound').values()]

def ips(names):
    target = ','.join(names)
    return [ips[0] for ips in __salt__['mine.get'](target, 'internal_ip', 'glob').values()]

def logstash_ip():
    ips = role_ips('monitor')
    if len(ips) > 0:
        return ips[0]
    return None

def monitor_ip():
    ips = role_ips('monitor')
    if len(ips) > 0:
        return ips[0]
    return None

def kibana_ip():
    ips = role_ips('kibana')
    if len(ips) > 0:
        return ips[0]
    return None

def ganglia_server_ip():
    ips = role_ips('ganglia')
    if len(ips) > 0:
        return ips[0]
    return None

def should_install(pkg):
    if pkg in ['elasticsearch', 'logstash', 'kibana', 'nodejs', 'nginx']:
        version = __salt__['pillar.get']('{0}:version'.format(pkg), '')
        current_version = __salt__['pkg.version'](pkg)
        return not current_version.startswith(version)
    else:
        raise NotImplemented()

def smtp_configured():
    '''Check if the following required parameters are defined (not None):
    host, port, username, password
    '''
    smtp_cfg = __salt__['pillar.get']('smtp', {})
    req_fields = ['host', 'username', 'password', 'port']
    return all((False if smtp_cfg.get(key) is None else True for key in req_fields))

def has_role(role):
    return role in __salt__['grains.get']('roles')

def local_ipv4():
    ''' ipv4 of local interface defined in pillar network.interface '''
    iface = __salt__['grains.get']('network:internal_ip', 'eth0')
    return __salt__['grains.get']('ip4_interfaces:{0}'.format(iface))[0]

def nginx_web_servers(state):
    '''
    state is either 'enabled' or 'disabled'
    '''
    from_pillar_ips = __salt__['pillar.get']('own_stack_cmd:balancer:{state}:server_ips'.format(state = state), None)
    log.debug('nginx_web_servers ips ' + str(from_pillar_ips))
    if from_pillar_ips is not None:
        return from_pillar_ips
    from_pillar_names = __salt__['pillar.get']('own_stack_cmd:balancer:{state}:server_names'.format(state = state), None)
    log.debug('nginx_web_servers names ' + str(from_pillar_names))
    if from_pillar_names is not None:
        from_pillar_ips = ips(from_pillar_names)
    return from_pillar_ips

def app_version(name):
    if name is None:
        raise ValueError('name cannot be None')
    cmd_name = __salt__['pillar.get']('own_stack_cmd:app_name')
    cmd_version = __salt__['pillar.get']('own_stack_cmd:app_rev')
    if cmd_name == name:
        return cmd_version
    return __salt__['pillar.get']('apps:{}:rev'.format(name))
