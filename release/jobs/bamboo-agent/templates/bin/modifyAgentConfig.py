from json import load
import xml.etree.ElementTree

specFile = open('/var/vcap/bosh/spec.json')
spec = load(specFile)
specFile.close()

configTree = xml.etree.ElementTree.parse('/var/vcap/data/bamboo-agent/bamboo-agent.cfg.xml')
name = configTree.find("agentDefinition/name")
name.text = "BOSH Agent: " + spec['id']

configTree.write('/var/vcap/data/bamboo-agent/bamboo-agent.cfg.xml')
