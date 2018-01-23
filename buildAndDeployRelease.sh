#!/bin/bash

# Setup of a new/empty director from fresh bosh-lite install procedure
# For first run (blank director) add `--us --postgre --alias --route` as script arguments to upload stemcell, install postgres release, and create handy bosh alias.
# All subsequent runs in development cycle can omit those flags.

set -e

# Cloud config specifies network, vm sizes, etc.
bosh -e vbox update-cloud-config cloud-config-vbox.yml
#provide stemcell,get latest URL for "warden bosh-lite" from bosh.io
if [[ $* == *--us* ]];then
  echo "Uploading stemcell"
   bosh -e vbox us https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3468.19-warden-boshlite-ubuntu-trusty-go_agent.tgz
fi

## use community postgres - https://github.com/cloudfoundry/postgres-release
if [[ $* == *--postgres* ]];then
 echo "Uploading postgres from community"
 bosh -e vbox upload-release https://bosh.io/d/github.com/cloudfoundry/postgres-release
fi


# you need to download jdk8 and bamboo from vendor, assumes they are in ~/Downloads
# These commands must be run after any changes to the release files
pushd release
mkdir -p blobs/bamboo
mkdir -p blobs/jdk8
bosh add-blob ~/Downloads/atlassian-bamboo-6.2.9.tar.gz bamboo/atlassian-bamboo-6.2.9.tar.gz
bosh add-blob ~/Downloads/jdk-8u162-linux-x64.tar.gz jdk8/jdk-8u162-linux-x64.tar.gz
bosh create-release --force
bosh -e vbox upload-release
popd


# There is now a release created and uploaded, below is actual deployment of release


#deploy!
bosh -e vbox -d bamboo deploy manifest.yml --recreate


if [[ $* == *--alias* ]];then
  echo "Setting alias for bosh to incliude environment and deployment"
  alias bosh='bosh -e vbox -d bamboo'
fi


if [[ $* == *--route* ]];then
  # routes traffic to containers through bosh-lite created in virtualbox
  #  i.e. traffic for bamnboo master on 192.168.100.11 will route through 192.168.50.6
  #                   bosh network     IP for bosh-lite vbox
  sudo route add -net 192.168.100.0/24 192.168.50.6
fi
