
# bosh deployment with Bambo Agent APIs
This project is mostly a proof of concepts that uses bosh as well as [agent apis for bamboo](https://bitbucket.org/eddiewebb/bamboo-agent-apis) to support administration of a large scale Bamboo build farm.

<!-- TOC START min:1 max:3 link:true update:true -->
- [bosh deployment with Bambo Agent APIs](#bosh-deployment-with-bambo-agent-apis)
  - [Features](#features)
  - [Tech used](#tech-used)
  - [Action Shots](#action-shots)
- [Building & Deploying the Release](#building--deploying-the-release)
    - [Note on Blob versions](#note-on-blob-versions)
    - [Build release and push to bosh director](#build-release-and-push-to-bosh-director)
  - [Manifest Values](#manifest-values)
  - [References](#references)
    - [Networking](#networking)
    - [Lifecycle](#lifecycle)
    - [Bosh VM Directories](#bosh-vm-directories)
  - [TODOs](#todos)

<!-- TOC END -->



## Features
- Allows fully automated upgrades to all remote agents with a single command `bosh deploy`
- Intelligently manages lifecycle of build agents (using pre-start, start, and drain)
    - will wait for existing builds to complete
    - mark agent disabled
    - take agent offline, upgrade/replace
    - bring agent online
    - `bosh start` will mark agent enabled check for any open tasks to complete (see api docs)
- Uses persistent store for consistent agent IDs as they update over time
- Sets agent name in Bamboo to the job instance container id.

## Tech used
- BOSH provides main orchestration of services
- monit provides service monitoring and automated restarts
- Java used in [related Bamboo plugin](https://bitbucket.org/eddiewebb/bamboo-agent-apis)
- Python, Bash/Shell and various linux tools support scripts

## Action Shots
Agent names in Bamboo will use bosh container IDs.
![Agent names in bamboo match bosh container id](/material/images/aafb-agent-ids-match-bamboo.png)
BOSH drain script marks agents disabled to prevent new work from being assigned to them
![Agents are marked disabled while current workload completes before being destroyed/updated](/material/images/aafb-agent-marked-disabled.png)
BOSH drain scripts for agents block for any running workloads to complete
![deletes and halts wait for running bamboo jobs](/material/images/aafb-delete-wait.png)


# Building & Deploying the Release

1. Install Bosh-lite based on vendor docs (this repo assumes default network on virtualbox defined there)
1. Download JDK8 and Atlassian Bamboo from vendor sites.  If they differ than those defined in [blobs.yml](release/config/blobs.yml) then you'll need to update file names and possibly some templates.
2. Run [`./buildAndDeployRelease --us --postgre --alias --route`](buildAndDeployRelease.sh)
 1. uploads stemcells
 2. sets cloud config for network and vminfo
 3. uploads community [postgres releases](https://github.com/cloudfoundry/postgres-release)
 4. builds and uploads this [bamboo releases](release)
 5. Triggers initial deploy of [sample manifest](manifest.yml)
 6. to iterate development re-run the build script omitting flags. [`./buildAndDeployRelease`](buildAndDeployRelease.sh)


### Note on Blob versions
You'll need to download jdk8 and the atlassian bamboo version to match those found in [blobs.yml](release/config/blobs.yml). You may manually add them using CLI, or leave them in `~/Downloads` for the [setup script](buildAndDeployRelease.sh) to add them as part of setup.


### Build release and push to bosh director
See bosh-lite docks for quick setup, or target your existing director

See `buildAndDeployRelease.sh` for individual steps, or run it to deploy the current config.

## Manifest Values
- `api.enabled` - make use of Agent APIs? (otherwise shutdowns will just be a hard kill, interupting any running jobs. And capabilities in config may not match the current agent, risking build failures)
- `api.token.uuid` - Valid token from [agent apis for bamboo](https://bitbucket.org/eddiewebb/bamboo-agent-apis) created in admin UI with 'change' permission
- bosh `process` block (just tips, defaults work)
 - `watch_time` defines how long we let jobs run before forcing an agent or giving up (depening on cli command)
 - `max_in_flight` - this si critical to make sure all your agents don't go offline at once! Set to 1 for small farms or a small percentage of large farms
 - `canaries` - 1 is fine, bosh release should include all smoke tests ot use on start


## References

### Networking
This approach to virtualbox networking is a result of my learnings on https://github.com/eddiewebb/concourse-pipeline-bosh-virtualbox

### Lifecycle
Understanding the lifecycle of BOSH jobs is critical to understand how this plugin interacts with the APIS at the right times, as well as the proper design of job specs.
https://bosh.io/docs/job-lifecycle.html

#### Stopping
- monit unmonitor is called for each process
- drain scripts run for all jobs on the VM in parallel
  (waits for all drain scripts to finish)
- monit stop is called for each process
- Persistent disks are unmounted on the VM if configured




### Bosh VM Directories
Useful info for troubleshooting.
 i.e. `bosh -e vbox -d bamboo ssh bamboo-server`
https://bosh.io/docs/vm-config.html

/var/vcap/data/: Directory that is used by the release jobs to keep ephemeral data. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/data/redis-server).

/var/vcap/store/: Directory that is used by the release jobs to keep persistent data. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/store/redis-server).

/var/vcap/sys/run/: Directory that is used by the release jobs to keep miscellaneous ephemeral data about currently running processes, for example, pid and lock files. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/sys/run/redis-server).

/var/vcap/sys/log/: Directory that is used by the release jobs to keep logs. Each release job usually creates a sub-folder with its name for namespacing (e.g. redis-server will place data into /var/vcap/sys/log/redis-server). Files in this directory are log rotated on a specific schedule configure by the Agent.


## TODOs
1) Script to setup agent tokens and rules
2) Install agent API plugins
3) Separate agent API job/specialites from bamboo with bosh "operator" files provided by CLI v2
