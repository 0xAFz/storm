import os
import sys
import yaml
from cloudflare import Cloudflare


def get_env(key):
    value = os.environ.get(key)
    if value is None or value.strip() == "":
        print(f"{key} can't be empty")
        sys.exit(1)
    return value

def load_env():
    return {
            "DOMAIN": get_env("DOMAIN"),
            "SUBDOMAIN": get_env("SUBDOMAIN"),
            "CLOUDFLARE_EMAIL": get_env("CLOUDFLARE_EMAIL"),
            "CLOUDFLARE_API_TOKEN": get_env("CLOUDFLARE_API_TOKEN"),
            "ZONE_ID": get_env("ZONE_ID"),
            }

def load_inventory():
    if not os.path.exists("ansible/inventory/hosts.yml"):
        print("ansible/hosts.yml does not exist.")
        sys.exit(1)

    with open("ansible/inventory/hosts.yml", "r") as file:
        inventory = yaml.safe_load(file)

    return inventory

def get_dns_records_list():
    return cf.dns.records.list(zone_id=config["ZONE_ID"]).model_dump()

def get_dns_record_dict(records):
    record_dict = {}
    for record in records["result"]:
        if record["name"] not in record_dict:
            record_dict[record["name"]] = []
        record_dict[record["name"]].append(record)
    return record_dict

def get_dns_record(name, records_dict):
    return records_dict.get(name, [])

def create_dns_record(type, name, content, proxied):
    return cf.dns.records.create(zone_id=config["ZONE_ID"], type=type, name=name, content=content, proxied=proxied)

def delete_dns_record(record):
    if isinstance(record, list):
        for r in record:
            cf.dns.records.delete(dns_record_id=r["id"], zone_id=config["ZONE_ID"])
            print(f"Deleted record: {r['name']} <{r['content']}>")
        return True    
    elif isinstance(record, dict):
        cf.dns.records.delete(dns_record_id=record["id"], zone_id=config["ZONE_ID"])
        print(f"Deleted record: {record['name']} <{record['content']}>")
        return True
    else:
        print("Invalid record format. Nothing to delete.")
    return False

def main():
    inventory = load_inventory()

    ips = []
    try:
        for host in inventory['all']['children']['master']['hosts']:
            ips.append(inventory['all']['children']['master']['hosts'][host]['ansible_host'])
    except Exception as e:
        print(e)
        sys.exit(1)
        
    records = get_dns_records_list()
    records_dict = get_dns_record_dict(records)

    record = get_dns_record(f"{config['SUBDOMAIN']}.{config['DOMAIN']}", records_dict)

    if record:
        delete_dns_record(record)
        
    for ip in ips:
        created = create_dns_record("A", f"{config['SUBDOMAIN']}.{config['DOMAIN']}", ip, True)
        if created:
            print(f"New DNS record created: <{ip}>")

if __name__ == "__main__":
    config = load_env()

    cf = Cloudflare(
        api_token=config.get("CLOUDFLARE_API_TOKEN"),
        api_email=config.get("CLOUDFLARE_EMAIL"),
    )

    main()
