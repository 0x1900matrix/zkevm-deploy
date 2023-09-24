#!/bin/bash

set -e

scripts_dir=$(cd $(dirname $0); pwd)
js_dir=$scripts_dir/../js
config_dir=$scripts_dir/../config

WORKDIR=$scripts_dir/../../

CONTRACTS=$WORKDIR/zkevm-contracts
NODE=$WORKDIR/zkevm-node


download_binary() {
    if [ ! -d $NODE ]; then
        cd $WORKDIR
        echo "zkevm-node not found, download zkevm-node"
        git clone https://github.com/0xEigenLabs/zkevm-node.git
    fi
    if [ ! -d $CONTRACTS ]; then
        cd $WORKDIR
        echo "zkevm-contracts not found, download zkevm-contracts"
        git clone https://github.com/0xPolygonHermez/zkevm-contracts.git
    fi
}

run_l1_node() {
    cd $NODE/test
    echo "run l1 node"
    make run-network
}

deploy_contracts_on_l1() {
    echo "generate deployer account"
    cd $js_dir
    node generate.js ../config/accounts.json

    echo "generate deploy_parameter.json"
    cd $scripts_dir
    python l2config.py generate_deploy_parameter --accounts ../config/accounts.json --output ../config/deploy_parameters.json

    echo "deploy bridge and consensus contract on l1"
    cp $config_dir/deploy_parameters.json $CONTRACTS/deployment/
    cp $config_dir/env $CONTRACTS/.env
    cd $CONTRACTS
    rm deployment/deploy_ongoing.json
    npm run deploy:testnet:ZkEVM:localhost
    cp deployment/deploy_output.json $config_dir/
    cp deployment/genesis.json $config_dir/
}

run_l2_node() {
    # generate genesis for l2
    cd $scripts_dir
    python l2config.py generate_genesis --deploy_output ../config/deploy_output.json --genesis ../config/genesis.json --output ../config/genesis_l2.json
    cp $config_dir/genesis_l2.json $NODE/test/test.genesis.config.json
    # TODO

}


run_l2_node
exit 0

download_binary
run_l1_node
sleep 10

deploy_contracts_on_l1