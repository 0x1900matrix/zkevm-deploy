import json
import os
import logging

import argparse

import logging
logging.basicConfig()
logging.getLogger().setLevel(logging.INFO)

def parse_argument():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["generate_genesis", "generate_deploy_parameter"])
    parser.add_argument("--genesis", type=str, default="../config/genesis.json", help="genesis.json after deploy contract on l1")
    parser.add_argument("--deploy_output", type=str, default="../config/deployt_output.json", help="deploy_output.json after deploy contract on l1")
    parser.add_argument("--accounts", type=str, default="../config/accounts.json", help="accounts file")
    parser.add_argument("--output", type=str, help="output path")
    return parser.parse_args()




def generate_genesis(genesis_src, deploy_output, genesis_dst):
    with open(genesis_src, 'r') as openfile:
        genesis = json.load(openfile)
    with open(deploy_output, 'r') as openfile:
        output = json.load(openfile)

    result = {
        "l1Config": {
		    "chainId": 1337,
		    "polygonZkEVMAddress": output["polygonZkEVMAddress"],
		    "maticTokenAddress": output["maticTokenAddress"],
		    "polygonZkEVMGlobalExitRootAddress": output["polygonZkEVMGlobalExitRootAddress"]
        },
        "genesisBlockNumber": output["deploymentBlockNumber"]
    } 
    result.update(genesis)
    with open(genesis_dst, 'w') as f:
        f.write(json.dumps(result, indent=2))
    
    # TODO: generate index.json
    # with open('../config/index.json', 'w') as f:
    #     f.write(json.dumps(index, indent=2))

def generate_deploy_parameter(accounts_path, output):
    try:
        with open(accounts_path, 'r') as f:
            accounts_ori = f.read()
        accounts = json.loads(accounts_ori)
    except Exception as e:
        logging.error("open acocunts {} failed, err={}", accounts_path, err)
        raise e
    logging.info('accounts {}'.format(json.dumps(accounts, indent=2)))

    with open('../config/deploy_parameters.json.example', 'r') as f:
        config_str = f.read()
    config = json.loads(config_str)
    for k, v in config.items():
        if v == '0x9A8645c226f7c32B57DF140232445231911C7399':
            config[k] = accounts['deployerAccount']['address']
    with open(output, 'w') as f:
        f.write(json.dumps(config, indent=2))
    with open(os.path.dirname(output) + '/env', 'w') as f:
        f.write('MNEMONIC=\"{}\"\n'.format(accounts['deployerAccount']['mnemonic']['phrase']))
        f.write('INFURA_PROJECT_ID=\"\"\nETHERSCAN_API_KEY=\"\"')

# generate_genesis('genesis.json', 'deploy_output.json', 'output.json')
# generate_deploy_parameter("../config/accounts.json", "../config/deploy_parameters.json")

if __name__ == '__main__':
    args = parse_argument()
    if args.action == 'generate_deploy_parameter':
        generate_deploy_parameter(args.accounts, args.output)
    elif args.action == 'generate_genesis':
        generate_genesis(args.genesis, args.deploy_output, args.output)
        