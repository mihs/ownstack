apps:
  web:
    name: web
    run_as_user: deployer
    rev: master
    url: salt://files/apps/web
    source: 'salt' # git, salt
    balancer: True
    env:
      NODE_ENV: production
      PORT: 8080
