# ownstack. Full application deployment in the cloud with monitoring, logging, dashboard, auto-scaling.

This is a work in progress. While certain features do work, others are not yet implemented or do not work as expected.
This project started as a test ground for saltstack.

## Objectives

* Customizable deployment rule sets for each machine type
* Load balancing with nginx
* Centralized logging (rsyslog)
* Logging filters and storage (Logstash, ElasticSearch)
* System metrics (Ganglia, collectd, Graphite)
* Alerts (elastalert)
* Sample deployment of a remote git nodejs application with separate web and jobs roles and process monitoring with pm2
* Application analytics (statsd, Graphite)
* Logging dashboards (Kibana)
