from json import load
import xml.etree.ElementTree
import os.path

specFile = open('/var/vcap/bosh/spec.json')
spec = load(specFile)
specFile.close()

if not os.path.isfile('/var/vcap/data/bamboo-agent/bamboo-agent.cfg.xml'):
	root = xml.etree.ElementTree.Element("configuration")
	buildDir = xml.etree.ElementTree.SubElement(root,"buildWorkingDirectory")
	buildDir.text = "/var/vcap/data/bamboo-agent/xml-data/build-dir"
	definition = xml.etree.ElementTree.SubElement(root,"agentDefinition")
	name = xml.etree.ElementTree.SubElement(definition,"name")
	description = xml.etree.ElementTree.SubElement(definition,"description")
	configTree = xml.etree.ElementTree.ElementTree(root)
else:
	configTree = xml.etree.ElementTree.parse('/var/vcap/data/bamboo-agent/bamboo-agent.cfg.xml')
	name = definition.find("agentDefinition/name")
	description = definition.find("agentDefinition/description")

name.text = "BOSH: " + spec['id']
description.text = "BOSH Agent running on " + spec['id']

configTree.write('/var/vcap/data/bamboo-agent/bamboo-agent.cfg.xml')
