apps:
  jobs:
    name: jobs
    run_as_user: deployer
    rev: master
    url: salt://files/apps/jobs
    source: 'salt' # git, salt
    env:
      NODE_ENV: production
