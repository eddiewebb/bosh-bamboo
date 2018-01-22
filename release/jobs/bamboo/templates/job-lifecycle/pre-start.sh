#!/bin/bash



RUN_DIR=/var/vcap/sys/run/bamboo
LOG_DIR=/var/vcap/sys/log/bamboo
STORE_DIR=/var/vcap/store/bamboo
JOB_DIR=/var/vcap/jobs/bamboo
PACKAGE_DIR=/var/vcap/packages/bamboo

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

#replace COnnector and Context in vendors server.xml
BAM_XML=$PACKAGE_DIR/conf/server.xml #default provided by this release
xsltproc -o $PACKAGE_DIR/conf/server.xml $JOB_DIR/bamboo_install/conf/server.xml.xslt ${BAM_XML}
:q

#bamboo.cfg is a bit trickier as bamboo creates it on first load.
if [ -f $STORE_DIR/bamboo.cfg.xml ];then # subsequent starts
  BAM_XML=$STORE_DIR/bamboo.cfg.xml #previous version on permanent storage
  xsltproc -o $STORE_DIR/bamboo.cfg.xml $JOB_DIR/bamboo_home/bamboo.cfg.xml.xslt ${BAM_XML}
else
  echo "WARN: No bamboo.cfg.xml exists, assuming this is first run."
fi




# overlay any customized property files into the install directory (overide vendor install files)
cp -r $JOB_DIR/bamboo_install/bin/* $PACKAGE_DIR/bin
