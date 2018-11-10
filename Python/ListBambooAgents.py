#!/usr/bin/env python
# ListAgents.py
#
# Authors:
# Kevin Bickmore <kevin.bickmore@gmail.com>

 
import requests
import argparse
import json
import paramiko
import sys
import x_bamboo
 
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
 
 
if __name__ == '__main__':
  # Grab the bamboo agents
  agents = query_bamboo_agents(server, uuid)
 
  for agent in agents:
    print(agent)