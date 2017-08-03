def nginx_upstream_server_enabled(name, host=None, app_name=None):
    '''
    Make sure that nginx routes to 'host'
    '''
    if host is None:
        host = name
    port = salt['pillar.get']('apps:{}:env:PORT'.format(app_name), 80)
    ret = {'changes': {},
           'pchanges': {},
           'comment': '',
           'name': name,
           'result': True}
    ret.update(__salt__['file.managed'](
        name='/etc/nginx/{}/servers/{}.conf'.format(domain, host),
        source='salt://nginx/files/server.conf',
        user='root',
        group='root',
        template='jinja',
        context={'ip': host, 'port': port}))
    ret['name'] = name
    return ret

def nginx_upstream_server_disabled(name, host=None):
    '''
    Make sure that nginx does not route to 'host'
    '''
    if host is None:
        host = name
    ret = {'changes': {},
           'pchanges': {},
           'comment': '',
           'name': name,
           'result': True}
    ret.update(__salt__['file.absent'](
        name='/etc/nginx/servers/{}.conf'.format(host),
        user='root',
        group='root'))
    ret['name'] = name
    return ret
