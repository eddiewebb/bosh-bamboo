# bosh deployment with Bambo Agent APIs 
THis project uses bosh as well as (agent apis for bamboo)[https://bitbucket.org/eddiewebb/bamboo-agent-apis] to add some logic around lifecycle.

![Adds workload and capacity intelligence to pool of bamboo agents](/material/images/aafb-agent-marked-disabled.png)



## Features
- Uses persitent store for consistent agent IDs
- bosh job stops marks agent disabled in bamboo, and will wait for any running bamboo jobs to complete (up to `update_watch_time`)![jobs will wait for running work on stop](/material/images/aafb-stop-log.png)
- bost start will mark agent enabled check for any open tasks to complete (see api docs)
- When scaling down, agents wait for running jobs before halting/deleting![deletes and halts wait for running bamboo jobs](/material/images/aafb-delete-wait.png)
- Sets agent name in Bamboo to the job instance container id. ![AGent names in bamboo match bosh container id](/material/images/aafb-ids-match-bamboo.png)

## Setup the Release
### Blobs
You'll need java and the atlassian bamboo version to match:
```
release/blobs/
├── bamboo
│   └── atlassian-bamboo-5.9.7.tar.gz
└── jdk8
    └── OpenJDK-1.8.0.66-x86_64-bin.tar.xz
```

### Build release and push to bosh director
See bosh-lite docks for quick setup, or target your existing director

See `buildAndDeployRelease.sh` for individual steps, or run it to deploy the current config.

## Manifest Values
- Add valid agent-api token  (api.token.uuid)
- Specify gateway IP (see network config below for virtualbox example, or adjust for your cpi)
- bosh process bock (just tips, defaults work)
 - watch_time defines how long we let jobs run before forcing an agent or giving up (depening on cli command)
 - max_in_flight - this si critical to make sure all your agents don't go offline at once! Set to 1 for small farms or a small percentage of large farms
 - canaries - 1 is fine, bosh release should include all smoke tests ot use on start


## bosh-lite / local.0/24 192.168.50.4`

#### Getting started: Bamboo Agent COnfig
To enable these agents, you must:
- Enable remote agents in bamboo server
- Set TCP string in Bamboo's "general configuration" to match gateway IP from virtual box (192.168.50.1)
- Restart bamboo

#### Define Virtual Box Network
At the time of this writing, the VirtualBox CPI for Bosh-lite create a network names vboxnet1 using IP 192.168.54.1. You can not use that network for CPI config. Make sure atleast one other network exists, the IP range should not matter, but our manifest assumes .100.x range.

- Open VirtualBox
- Choose VirtualBox > Preferences > Network
- Create new network named vboxnet0 (used by cloud config).
- Suggested IP address: 192.168.100.1
- DHCP Server (tab) -> Uncheck Enable Server

##### bosh ssh 
This will allow bosh-cli to talk to all the containers the director spins up on .100.0/24 
`sudo route add -net 192.168.100

## NOte

### Networking
This approach to virtualbox networking is a result of my learnings on https://github.com/eddiewebb/concourse-pipeline-bosh-virtualbox

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