#!/usr/bin/env python3
# BambooAgentCleanup.py
#
# Authors:
# Kevin Bickmore <kevin.bickmore@gmail.com>

 
import requests
import argparse
import json
import paramiko
import sys
import x_bamboo
 
server = "bamboo.domain.com" ### Update this to reflect your org
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
 
pythonversioncheck()

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Bamboo Agent API key')
  parser.add_argument('ApiKey', type=str)
  args = parser.parse_args()
 
  # Create the SSH object
  ssh = paramiko.SSHClient()
  ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
 
  # Grab the bamboo agents
  agents = query_bamboo_agents(server, uuid)
 
  for agent in agents:
    if agent['online'] and not agent['busy']:
      # Disable the agent
      disable_agent(agent)
 
      # Wait a sec
      time.sleep(1)
 
      # Verify disable worked
      if is_enabled(agent):
        print(f"Error disabling {agent['name']}. Skipping agent")
        next
 
      # Verify that we have the proper capabilities
      caps = get_capabilities(agent)
      if 'clean-me' in caps.keys():
        # This agent is able to be cleaned.
 
        # Currently, we only support Ubuntu
        # (this should be wrapped in a try, in case the key isn't there)
        if caps['system.distribution.id'] == 'Ubuntu':
          try:
            clean_agent(agent)
          except Exception as err:
            print(f"Error cleaning {agent['name']}: {str(err)}")
            print("... continuing")
 
      enable_agent(agent)
      if not is_enabled(agent):
        print(f"Error re-enabling {agent['name']} after cleaning. Please manually restart." )