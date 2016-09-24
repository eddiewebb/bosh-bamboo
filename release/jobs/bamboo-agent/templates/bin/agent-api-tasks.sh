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
	curl -H "X-Atlassian-Token:nocheck" -X GET -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/state/text?uuid=${uuid}" -o ${TMPDIRD}/state.txt 2>/dev/null	
	echo "Status API returned:"
	cat ${TMPDIRD}/state.txt
	echo ""
	source ${TMPDIRD}/state.txt
}


disableAgent(){
	curl -H "X-Atlassian-Token:nocheck" -X POST -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/state/disable?uuid=${uuid}" -o ${TMPDIRD}/state.json 2>/dev/null	
	echo "Disable API returned:"
	cat ${TMPDIRD}/state.json
	echo ""
}

enableAgent(){
	curl -H "X-Atlassian-Token:nocheck" -X POST -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/state/enable?uuid=${uuid}" -o ${TMPDIRD}/state.json 2>/dev/null	
	echo "Enable API returned:"
	cat ${TMPDIRD}/state.json
	echo ""
}

requestMaintenance(){
	SIBLING_PATIENCE_TIME=30 # will wait 1 minutes
	SIBLING_PATIENCE_COUNT=10 # will repeat 15 times.

	curl -H "X-Atlassian-Token:nocheck" -X POST -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/maintenance?uuid=${uuid}" -o ${TMPDIRD}/state.text 2>/dev/null	
	echo "Chaperone API returned:"
	cat ${TMPDIRD}/state.text
	source ${TMPDIRD}/state.text
	echo ""
    if [[ "$PCODE" == "YES_CHILD" ]]
    then
        #server says we can upgrade, make sure we are idle.
        echo "Capacity available on master, request granted, agent disabled"
    elif [[ "$PCODE" == "WAIT_FOR_SIBLINGS" ]]
    then
        # allowed to upgrae, but too many others are working right now, check back in a few
        echo "Master server wants me to wait, this is my $attempts attempt."
        echo "${PCODE}: ${PMESSAGE}"
        if [ $attempts -gt $SIBLING_PATIENCE_COUNT ]
        then
            echo "Siblings have exhausted my patience. INcrease wait times, offset cycles, or increase concurrency"
            exit 9
        fi
        let attempts+=1
        sleep $SIBLING_PATIENCE_TIME
        requestMaintenance #will recurse back into this functuion
    elif [[ "$PCODE" == "NO_CHILD" ]]
    then
        echo "Master server is refusing updates."
        echo "$PCODE: $PMESSAGE"
        exit 9
    elif [[ "$PCODE" == "UH_OH" ]]
    then
        echo "ERROR:  Master server is reporting an issue."
        echo "$PCODE: $PMESSAGE ,  existing Task ID: $TASK"
        exit 0
    else
        echo "ERROR:  I don't understand server response!"
        cat ${TMPDIRD}/state.txt
        exit 0
    fi
}

completeAgentTaskIfOpen(){
	TASK=""
	curl -H "X-Atlassian-Token:nocheck" -X GET -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/maintenance/text?uuid=${uuid}" -o ${TMPDIRD}/openTask.txt 2>/dev/null	
	source ${TMPDIRD}/openTask.txt
	if [ "x${TASK}" == "x" ];then
		echo "No open tasks, normal startup"
	else
		echo "Mark open task complete to re-enable this agent."
		curl -H "X-Atlassian-Token:nocheck" -X PUT -k -b ${TMPDIRD}/cookies "${bambooUrl}rest/agents/latest/${agentId}/maintenance/task/${TASK}/finish?uuid=${uuid}" -o ${TMPDIRD}/state.txt 2>/dev/null	
		echo "Complete Task API returned:"
		cat ${TMPDIRD}/state.txt
		source ${TMPDIRD}/state.txt
	fi
	rm ${TMPDIRD}/openTask.txt
}