#!/bin/sh
#


#
#  NOTE: these are aggressively low timings to expediate demonstration of agents joining and dropping. A real environment would be times ~10x this.
#
JVM_SUPPORT_RECOMMENDED_ARGS="-Dbamboo.agent.heartbeatInterval=5 -Dbamboo.agent.heartbeatTimeoutSeconds=10 -Dbamboo.agent.heartbeatCheckInterval=3"

#
# The following 2 settings control the minimum and maximum given to the Bamboo Java virtual machine.  In larger Bamboo instances, the maximum amount will need to be increased.
#
JVM_MINIMUM_MEMORY="256m"
JVM_MAXIMUM_MEMORY="512m"

#
# The following are the required arguments need for Bamboo standalone.
#
JVM_REQUIRED_ARGS=""

#-----------------------------------------------------------------------------------
#
# In general don't make changes below here
#
#-----------------------------------------------------------------------------------

PRGDIR=`dirname "$0"`
cat "${PRGDIR}"/bamboobanner.txt

# provided by bin/bamboo which calls startup.sh
BAMBOO_HOME_MINUSD=-Dbamboo.home=$BAMBOO_HOME

JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${BAMBOO_HOME_MINUSD}"


# Perm Gen size needs to be increased if encountering OutOfMemoryError: PermGen problems. Specifying PermGen size is not valid on IBM JDKs
BAMBOO_MAX_PERM_SIZE=256m
if [ -f "${PRGDIR}/permgen.sh" ]; then
    echo "Detecting JVM PermGen support..."
    . "${PRGDIR}/permgen.sh"
    if [ $JAVA_PERMGEN_SUPPORTED = "true" ]; then
        echo "PermGen switch is supported. Setting to ${BAMBOO_MAX_PERM_SIZE}"
        JAVA_OPTS="-XX:MaxPermSize=${BAMBOO_MAX_PERM_SIZE} ${JAVA_OPTS}"
    else
        echo "PermGen switch is NOT supported and will NOT be set automatically."
    fi
fi

JAVA_OPTS=$(echo "$JAVA_OPTS" | sed -e 's/\s*$//' -e 's/^\s*//')
export JAVA_OPTS

echo ""
echo "If you encounter issues starting or stopping Bamboo Server, please see the Troubleshooting guide at https://confluence.atlassian.com/display/BAMBOO/Installing+and+upgrading+Bamboo"
echo ""
#if [ "$BAMBOO_HOME_MINUSD" != "" ]; then
#    echo "Using BAMBOO_HOME:       $BAMBOO_HOME"
#fi
