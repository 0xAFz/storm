import os
import json
import yaml
import subprocess

terraform_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'terraform')

terraform_output = subprocess.check_output(
    ["terraform", "output", "-json", "instance_public_ips"],
    cwd=terraform_dir
)

# terraform_output = subprocess.check_output(["terraform", "output", "-json", "instance_public_ips"])

ips = json.loads(terraform_output)

controller_ip = ips[0]

worker_ips = ips[1:]

inventory = {
    'all': {
        'children': {
            'controller': {
                'hosts': {
                    f'controller1': {
                        'ansible_host': controller_ip,
                        'ansible_user': 'root',
                        'ansible_port': 22,
                    }
                }
            },
            'worker': {
                'hosts': {}
            }
        }
    }
}

for i, ip in enumerate(worker_ips, 1):
    inventory['all']['children']['worker']['hosts'][f'worker{i}'] = {
        'ansible_host': ip,
        'ansible_user': 'root',
        'ansible_port': 22,
    }

with open('ansible/inventory/hosts.yml', 'w') as file:
    yaml.dump(inventory, file, default_flow_style=False, indent=2)

print("Inventory file 'hosts.yml' generated successfully!")
