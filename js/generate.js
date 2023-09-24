const ethers = require("ethers");
const fs = require('fs');

const args = process.argv.slice(2);

const MNEMONIC="test test test test test test test test test test test junk";
const initAccount = ethers.Wallet.fromMnemonic(MNEMONIC);

let output = {};
output.initAccount = {
    privateKey: initAccount.privateKey,
    address: initAccount.address,
    mnemonic: initAccount.mnemonic
}

let deployer = ethers.Wallet.createRandom()

output.deployerAccount = {
    privateKey: deployer.privateKey,
    address: deployer.address,
    mnemonic: deployer.mnemonic
}

// transfer ether to deployer

var provider = new ethers.providers.JsonRpcProvider("http://localhost:8545")
const signer = initAccount.connect(provider);

provider.getBalance(initAccount.address).then((data, err) => {
    console.log('test account balance', data)
})
console.log("transfer 1 ether to deployer account")
signer.sendTransaction({
    to: deployer.address,
    value: ethers.utils.parseUnits("1")
}).then((tx) => {
    console.log('tx hash', tx.hash)
    tx.wait().then((receipt) => {
        console.log('tx hash', receipt.transactionHash)
    })
})

provider.getBalance(deployer.address).then((data, err) => {
    console.log('deployer account balance', data)
})

console.log("write accounts info to", args[0])
fs.writeFileSync(args[0], JSON.stringify(output), 'utf8')
