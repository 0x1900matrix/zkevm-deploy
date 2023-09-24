import os
import json

with open('../js/accounts.json', 'r') as f:
    accounts_ori = f.read()

accounts = json.loads(accounts_ori)
print(json.dumps(accounts, indent=4))