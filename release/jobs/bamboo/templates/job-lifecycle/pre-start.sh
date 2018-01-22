#!/bin/bash



RUN_DIR=/var/vcap/sys/run/bamboo
LOG_DIR=/var/vcap/sys/log/bamboo
STORE_DIR=/var/vcap/store/bamboo
JOB_DIR=/var/vcap/jobs/bamboo

export JAVA_HOME=/var/vcap/packages/jdk8
export PATH=$JAVA_HOME/bin:$PATH


mkdir -p $RUN_DIR $LOG_DIR $STORE_DIR
chown -R vcap:vcap $RUN_DIR $LOG_DIR $STORE_DIR

apt-get update
apt-get --yes --force-yes install postgresql-client-9.6
apt-get --yes --force-yes install git
apt-get --yes --force-yes install xsltproc

# Bosh places our template files in /var/vcap/jobs/bamboo.
# Anything we need elsewhere (i.e. permanemt storage /var/vcap/store) must be moved.


#replace current or default bamboo.cfg injecting properties with xslt
if [ -f $STORE_DIR/bamboo.cfg.xml ];then
  BAM_XML=$STORE_DIR/bamboo.cfg.xml #previous version on permanent storage
else
  BAM_XML=$JOB_DIR/bamboo_home/bamboo.cfg.xml #default provided by this release
fi
xsltproc -o $STORE_DIR/bamboo.cfg.xml $STORE_DIR/bamboo.cfg.xml.xslt ${BAM_XML}

# overlay any customized property files into the install directory (overide vendor install files)
cp -r /var/vcap/jobs/bamboo/bamboo_install/* /var/vcap/packages/bamboo/
