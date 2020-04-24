import requests
import argparse
import json
import paramiko
import sys
 
parser = argparse.ArgumentParser(description='Bamboo Agent API key')
parser.add_argument('ApiKey', type=str)
args = parser.parse_args()
 
url = 'https://bamboo.domain.com/rest/agents/latest/?uuid={0}'.format(args.ApiKey)
response = requests.get(url, verify=False).json()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
exit_status = 0
for agent in response:
    json_dump = json.dumps(agent)
    json_obj = json.loads(json_dump)
    idval = json_obj.get('id')
    host = json_obj.get('name')
    enabled = json_obj.get('enabled')
    busy = json_obj.get('busy')
    online = json_obj.get('online')
    print('ID=', idval, 'name=', host, 'enabled=', enabled, 'busy=', busy, 'online=', online)
    if busy == False and online == True:
        ### Disable agent
        disableurl = 'https://bamboo.domain.com/rest/agents/latest/{0}/state/disable?uuid={1}'.format(idval, args.ApiKey)
        requests.post(disableurl, verify=False)
        ### Verify agent is disabled
        agentcheckurl ='https://bamboo.domain.com/rest/agents/latest/{0}/state/?uuid={1}'.format(idval, args.ApiKey)
        isDisabled = requests.get(agentcheckurl, verify=False).json()
        if isDisabled.get('enabled') == False:
            print(host,'has been disabled in bamboo.')
        ### End Disable agent
        ###
        ### Get agent capabilities
        agenturl = 'https://bamboo.domain.com/rest/agents/latest/{0}/capabilities?uuid={1}'.format(idval, args.ApiKey)
        agentcapabilities = requests.get(agenturl, verify=False).json()
        for capability in agentcapabilities:
            ### Verify that agent is linux
            if capability.get('key') == 'system.distribution.id' and capability.get('value') == 'Ubuntu':
                ItIsLinux = True
            if capability.get('clean-me') == 'true':
                ReadyToClean = True
        ### End agent capabilities check
        ###
        ### If linux proceed with bamboo agent cleanup
        if ItIsLinux == True and ReadyToClean == True:
            try:
                ssh.connect(host, username='root', key_filename='/path/to/sshkey')
                print("Connected to ", host)
                connected = True
            except paramiko.AuthenticationException as autherror:
                print(str(autherror))
                exit_status = 1
            if connected == True:
                stdin, stdout, stderr = ssh.exec_command('systemctl stop docker.service bamboo-agent.service; rm -rf /var/lib/docker/*; rm -rf /home/ubuntu/bamboo-agent-home/xml-data/build-dir/*; systemctl start docker.service bamboo-agent.service')
                print(stdout.readlines())
                print('Errors:')
                print(stderr.readlines())
                print('Command finished. Closing connection.')
            ssh.close()
            ### after cleanup reenable agent
            enableurl = 'https://bamboo.domain.com/rest/agents/latest/{0}/state/enable?uuid={1}'.format(idval, args.ApiKey)
            requests.post(enableurl, verify=False)
            ### Verify agent is reenabled
            isEnabled = requests.get(agentcheckurl, verify=False).json()
            if isEnabled.get('enabled') == True:
                print(host, 'has been enabled in bamboo.')
            ### End enable agent
        ### End agent cleanup
sys.exit(exit_status)