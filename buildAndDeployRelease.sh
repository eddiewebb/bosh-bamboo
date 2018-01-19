#!/bin/bash

# Setup of a new/empty director from fresh bosh-lite install procedure
# Only run these once, or customize to meet existing bosh directory Setup#use vbox config

# Cloud config specifies network, vm sizes, etc.
bosh -e vbox update-cloud-config cloud-config-vbox.yml
#provide stemcell,get latest URL for "warden bosh-lite" from bosh.io
#bosh -e vbox us https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3468.19-warden-boshlite-ubuntu-trusty-go_agent.tgz



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
bosh -e vbox -d bamboo deploy manifest.yml
