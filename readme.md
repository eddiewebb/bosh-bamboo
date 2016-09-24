# bosh deployment with Bambo Agent APIs 
THis project uses bosh (big woop, lots do) but layers in the use of Agent APIs for Bamboo.

## Features
- bosh job stops will wait for any running bamboo jobs to complete
- bost start will check for any tasks owned by agent, and mark complete
- uses Chaperone APIs to rebuild agents at regular intervals without more than n agents offline.


## Configure manifest
- Add valid agent-api token
- Specify gateway IP 


## bosh-lite / local
#### Bamboo Agent COnfig
- Enable remote agents
- Set TCP strong in general connection to match gateway IP from virtual box (192.168.50.1)
- Restart bamboo

#### Network/Virtual Box Config
See https://github.com/eddiewebb/concourse-pipeline-bosh-virtualbox for virtual box and network config
Make sure to run `https://github.com/eddiewebb/concourse-pipeline-bosh-virtualbox` to enable ssh access to agents.

## NOte

### Lifecycle
https://bosh.io/docs/job-lifecycle.html

####STopping
- monit unmonitor is called for each process
- drain scripts run for all jobs on the VM in parallel
  (waits for all drain scripts to finish)
- monit stop is called for each process
- Persistent disks are unmounted on the VM if configured




### Bosh Release DIrectorys
https://bosh.io/docs/vm-config.html

/var/vcap/data/: Directory that is used by the release jobs to keep ephemeral data. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/data/redis-server).

/var/vcap/store/: Directory that is used by the release jobs to keep persistent data. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/store/redis-server).

/var/vcap/sys/run/: Directory that is used by the release jobs to keep miscellaneous ephemeral data about currently running processes, for example, pid and lock files. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/sys/run/redis-server).

/var/vcap/sys/log/: Directory that is used by the release jobs to keep logs. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/sys/log/redis-server). Files in this directory are log rotated on a specific schedule configure by the Agent.