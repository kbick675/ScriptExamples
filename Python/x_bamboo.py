#!/usr/bin/env python
# sx_bamboo.py
#
# Authors:
# Kevin Bickmore <kevin.bickmore@domain.com>
# Matt Simmons <matthew.simmons@domain.com>
 
import requests
import argparse
import json
import paramiko
import sys
 
server = "bamboo.domain.corp" ### update this to reflect your org
uuid = ""
ssh_user = "root"
key_filename = "/path/to/key"
 
clean_commands = [
    "systemctl stop bamboo-agent.service",
    "systemctl stop docker.service",
    "rm -rf /var/lib/docker/*",
    "rm -rf /home/ubuntu/bamboo-agent-home/xml-data/build-dir/*",
    "systemctl start docker.service",
    "systemctl start bamboo-agent.service"
    ]
 
def query_bamboo_agents(server = server):
  """ Hits the Bamboo agents API and returns a list of dicts
      that contain the agents and their status
      See: https://docs.atlassian.com/atlassian-bamboo/REST/6.2.5/
  """
  url = "https://%s/rest/agents/latest/?uuid=%s" % server
  try:
    response = requests.get(url).json()
  except Exception as err:
    print("Error requesting bamboo agents: %s" % str(err))
    sys.exit(-1)
  return response
 
def disable_agent(dict_agent):
  """ Hits the Bamboo REST API to disable an agent """
  url = "https://%s/rest/agents/latest/%s/state/disable?uuid=%s" % (server, dict_agent['id'], uuid)
  try:
    res = requests.post(url)
  except Exception as err:
    print("Error disabling agent %s: %s" % (dict_agent['name'], str(err)))
    sys.exit(-1)
  return res
 
def enable_agent(dict_agent):
  """ Hits the Bamboo REST API to enable an agent """
  url = "https://%s/rest/agents/latest/%s/state/enable?uuid=%s" % (server, dict_agent['id'], uuid)
  try:
    res = requests.post(url)
  except Exception as err:
    print("Error enabling agent %s: %s" % (dict_agent['name'], str(err)))
    sys.exit(-1)
  return res
 
def is_enabled(dict_agent):
  """ Hits the Bamboo REST API to see if the agent is enabled. Returns bool"""
  url = "https://%s/rest/agents/latest/%s/state/?uuid=%s" % (server, dict_agent['id'], uuid)
  try:
    res = requests.get(url).json()
  except Exception as err:
    print("Error checking status of agent %s: %s" % (dict_agent['id'], str(err)))
    sys.exit(-1)
  return res['enabled']
 
def get_capabilities(dict_agent):
  """ Each bamboo agent has a set of capabilities. This retrieves a dictionary
      containing them
  """
  url = "https://%s/rest/agents/latest/%s/capabilities?uuid=%s" % (server, dict_agent['id'], uuid)
  try:
    res = requests.get(url).json()
  except Exception as err:
    print("Error getting capabilities of agent %s: %s" % (dict_agent['id'], str(err)))
  capabilities = {}
  for cap in res:
    capabilities[cap['key']] = cap['value']
  return capabilities
 
def clean_agent(dict_agent):
  """ Uses paramiko to connect to the agent and run some commands to clean up """
  # Normally we would wrap this, but we want to raise any errors anyway
  ssh.connect(dict_agent['name'], username=ssh_user, key_filename=ssh_key_path)
  clean_commands = ["echo 'Cleaning host'", "hostname"]
  stdin, stdout, stderr = ssh.exec_command("; ".join(clean_commands))
  ssh.close()
  return stderr.readlines()