const ethers = require("ethers");
const MNEMONIC="test test test test test test test test test test test junk";
const mnemonicWallet = ethers.Wallet.fromMnemonic(MNEMONIC);
console.log(mnemonicWallet.privateKey, mnemonicWallet.address);
const fs =require('fs')

var provider = new ethers.providers.JsonRpcProvider("http://localhost:8545")
const signer = mnemonicWallet.connect(provider);

provider.getBalance(mnemonicWallet.address).then((data, err) => {
console.log('balance', data, err)
})

let newwallet;


async function create() {
// newwallet = ethers.Wallet.createRandom()
// console.log(newwallet.mnemonic)
// console.log(newwallet.privateKey)
// console.log(newwallet.address)

newwallet = ether.Wallet.fromMnemonic("ride muffin deliver leave cargo code hundred remind alone absurd nephew thought")
}

async function send_l1() {
let newwallet = ethers.Wallet.fromMnemonic("ride muffin deliver leave cargo code hundred remind alone absurd nephew thought")
provider.getBalance(newwallet.address).then((data, err) => {
    console.log('balance1', data)
})
let tx = await signer.sendTransaction({
to: newwallet.address,
value: ethers.utils.parseUnits("1")
})
let receipt = await tx.wait()
console.log(receipt)
}

async function send_token() {
const rawerc20abi = fs.readFileSync("artifacts/@openzeppelin/contracts/token/ERC20/ERC20.sol/ERC20.json");
const erc20abi = JSON.parse(rawerc20abi).abi;
var token = new ethers.Contract("0x5FbDB2315678afecb367f032d93F642f64180aa3", erc20abi, signer)
console.log(await token.balanceOf(mnemonicWallet.address))

console.log(await token.balanceOf(newwallet.address))

/*
let tx = await mnemonicWallet.sendTransaction({
to: newwallet,
value: 10,
});
*/
var tx = await token.transfer(newwallet.address, ethers.utils.parseUnits("1.23"));
var receipt = await tx.wait();
console.log(receipt)
console.log(await token.balanceOf(newwallet.address))
}


/*
get_balance().then(() => {
console.log("done");
})
*/
async function all() {
// await create();
send_l1();

}
all().then(() => {
console.log("done")
})
