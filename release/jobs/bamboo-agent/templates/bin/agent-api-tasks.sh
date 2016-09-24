#!/bin/bash
#
# This is a blocking script that will not exit until Agent-APIS for this agent return an idle status
#

#Write Token UUID (Is a token created by Agent APIs for Bamboo authorization.)
uuid="<%= p("api.token.uuid") %>"

# URl of master server
bambooUrl="<%= p("server.protocol") %>://<%= p("server.ip") %>:<%= p("server.port") %><%= p("server.context") %>"

# Agent ID can be hard coded, but is easily pulled from the running system
agentId=`cat /var/vcap/data/bamboo-agent/bamboo-agent.cfg.xml | grep -oPm1 "(?<=<id>)[^<]+"`

# make a tmp dir for cookie jar and other random files we'll make
TMPDIRD=`mktemp -d /tmp/agentMaintenance.XXXXXX` || exit 1


purgeCapabilities(){
	curl -H "X-Atlassian-Token:nocheck" -X DELETE -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/capabilities?uuid=${uuid}" -o ${TMPDIRD}/capabilities.json 2>/dev/null
	echo "Capabilties Purged"
}


blockUntilIdle(){
    let busyWait=60
	while [ 1 -gt 0 ];do
		getStatus
		if [[ "${BUSY}" == "true" ]];then
        	echo "Agent is still performing  a build. Blocking ${busyWait} seconds to check back"
            sleep $busyWait
        else
        	echo "Agent is idle, allowing next steps to proceed. "
        	break
        fi
    done
}


getStatus(){
	curl -H "X-Atlassian-Token:nocheck" -X GET -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/state/text?uuid=${uuid}" -o $TMPDIRD/state.txt 2>/dev/null	
	echo "Status API returned:"
	cat ${TMPDIRD}/state.txt
	echo ""
	source ${TMPDIRD}/state.txt
}


disableAgent(){
	curl -H "X-Atlassian-Token:nocheck" -X POST -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/state/disable?uuid=${uuid}" -o $TMPDIRD/state.json 2>/dev/null	
	echo "Disable API returned:"
	cat ${TMPDIRD}/state.json
	echo ""
}

enableAgent(){
	curl -H "X-Atlassian-Token:nocheck" -X POST -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/state/enable?uuid=${uuid}" -o $TMPDIRD/state.json 2>/dev/null	
	echo "Enable API returned:"
	cat ${TMPDIRD}/state.json
	echo ""
}

completeAgentTaskIfOpen(){
	TASK=""
	curl -H "X-Atlassian-Token:nocheck" -X GET -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/maintenance/text?uuid=${uuid}" -o $TMPDIRD/openTask.txt 2>/dev/null	
	source ${TMPDIRD}/openTask.txt
	if [ "x${TASK}" == "x" ];then
		echo "No open tasks, normal startup"
	else
		echo "Mark open task complete to re-enable this agent."
		curl -H "X-Atlassian-Token:nocheck" -X PUT -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/maintenance/task/${TASK}/finish?uuid=${uuid}" -o $TMPDIRD/state.txt 2>/dev/null	
		echo "Complete Task API returned:"
		cat ${TMPDIRD}/state.txt
		source ${TMPDIRD}/state.txt
	fi
	rm ${TMPDIRD}/openTask.txt
}