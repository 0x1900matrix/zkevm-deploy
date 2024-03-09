#!/bin/bash

set -e

scripts_dir=$(cd $(dirname $0); pwd)
js_dir=$scripts_dir/../js
config_dir=$scripts_dir/../config

WORKDIR=$scripts_dir/../..

CONTRACTS=$WORKDIR/zkevm-contracts
NODE=$WORKDIR/zkevm-node
BRIDGE=$WORKDIR/zkevm-bridge-service
ABI=$WORKDIR/static


download_binary() {
    if [ ! -d $NODE ]; then
        cd $WORKDIR
        echo "zkevm-node not found, download zkevm-node"
        git clone https://github.com/0xEigenLabs/zkevm-node.git
    fi
    if [ ! -d $ABI ]; then
        cd $WORKDIR
        echo "download static"
        git clone https://github.com/maticnetwork/static.git
    fi
    if [ ! -d $CONTRACTS ]; then
        cd $WORKDIR
        echo "zkevm-contracts not found, download zkevm-contracts"
        git clone https://github.com/0xPolygonHermez/zkevm-contracts.git
        cd zkevm-contracts
        git checkout v1.1.0-fork.4
        cd ..
    fi
    if [ ! -d $BRIDGE ]; then
        cd $WORKDIR
        echo "zkevm-bridge not found, download zkevm-bridge-service"
        git clone https://github.com/0xPolygonHermez/zkevm-bridge-service.git
        cd zkevm-bridge-service
        git checkout 81740cee945888e2db351b2fafafc826ad095425
        cd ..
    fi

}

run_l1_node() {
    cd $NODE/test
    echo "run l1 node"
    make run-network
}

deploy_contracts_on_l1() {
    set -x
    echo "generate deployer account"
    cd $js_dir
    node generate.js ../config/accounts.json

    echo "generate deploy_parameter.json"
    cd $scripts_dir
    python l2config.py generate_deploy_parameter --accounts ../config/accounts.json --output ../config/deploy_parameters.json

    echo "deploy bridge and consensus contract on l1"
    cp $config_dir/deploy_parameters.json $CONTRACTS/deployment/
    cp $config_dir/env $CONTRACTS/.env
    cp $js_dir/1_createGenesis.js $CONTRACTS/deployment/
    cd $CONTRACTS
    if [ -f deployment/deploy_ongoing.json ]; then
        rm deployment/deploy_ongoing.json
    fi
    npm run deploy:testnet:ZkEVM:localhost
    cp deployment/deploy_output.json $config_dir/
    cp deployment/genesis.json $config_dir/
    set +x
}

run_l2_node() {
    # generate genesis for l2
    cd $scripts_dir
    python l2config.py generate_genesis --deploy_output ../config/deploy_output.json --genesis ../config/genesis.json --output ../config/genesis_l2.json
    cp $config_dir/genesis_l2.json $NODE/test/config/test.genesis.config.json
    deployer_priv=$(jq -r '.deployerAccount.privateKey' ${config_dir}/accounts.json)
    deployer_address=$(jq -r '.deployerAccount.address' ${config_dir}/accounts.json)
    sed 's/SenderAddress = TODO/SenderAddress = "'${deployer_address}'"/g' ${config_dir}/test.node.config.toml.example > ${config_dir}/test.node.config.toml
    cp ${config_dir}/test.node.config.toml ${NODE}/test/config/
    cd $NODE
    if [ ! -f ./dist/zkevm-node ]; then
        echo "build zkevm-node"
        make build
    fi
    rm -rf temp.keystore
    dist/zkevm-node encryptKey -pk ${deployer_priv} --pw testonly -o temp.keystore
    output_key=$(ls temp.keystore/)
    echo "sequencer.keystore ${output_key}"
    cp temp.keystore/${output_key} test/sequencer.keystore
    cd test
    make run-db
    sleep 5
    make run-approve-matic
    make run-zkprover
    sleep 10
    make run-node
}

prepare_bridge_service() {
    deployer_priv=$(jq -r '.deployerAccount.privateKey' ${config_dir}/accounts.json)
    deployer_address=$(jq -r '.deployerAccount.address' ${config_dir}/accounts.json)
    output_key=$(ls ${NODE}/temp.keystore/)
    echo "sequencer.keystore ${output_key}"
    cp ${NODE}/temp.keystore/${output_key} $BRIDGE/test/test.keystore.claimtx
    cp ${NODE}/temp.keystore/${output_key} $BRIDGE/test/test.keystore.sequencer
    cp ${config_dir}/config.local.toml ${BRIDGE}/config/

    # TODO: solve setting conflicts (i.e., port)
    cd $BRIDGE
    make run-db-bridge
    sleep 10
    make run-bridge
}

run_abi_service() {
    echo "TODO"
    mkdir -p $ABI/network/zkevm/0.0.1
    cp ${config_dir}/index.json $ABI/network/zkevm/0.0.1/

}



# download_binary
run_l1_node
sleep 10
# # # 
deploy_contracts_on_l1
sleep 10
# # # 
run_l2_node
prepare_bridge_service
run_abi_service