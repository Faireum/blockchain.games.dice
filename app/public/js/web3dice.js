//Abi for FaireumDice.sol
const abi = [ { "constant": true, "inputs": [], "name": "croupier", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "owner", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "lockedInBets", "outputs": [ { "name": "", "type": "uint128" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "inputs": [], "payable": false, "stateMutability": "nonpayable", "type": "constructor" }, { "payable": true, "stateMutability": "payable", "type": "fallback" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" } ], "name": "PaymentCompleted", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" } ], "name": "JackpotPaid", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "commit", "type": "uint256" }, { "indexed": false, "name": "user", "type": "address" }, { "indexed": false, "name": "amount", "type": "uint256" } ], "name": "BetPlaced", "type": "event" }, { "constant": false, "inputs": [ { "name": "newCroupier", "type": "address" } ], "name": "setCroupier", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [], "name": "kill", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "modulo", "type": "uint256" }, { "name": "commit", "type": "uint256" } ], "name": "placeBet", "outputs": [], "payable": true, "stateMutability": "payable", "type": "function" }, { "constant": false, "inputs": [ { "name": "reveal", "type": "uint256" }, { "name": "blockHash", "type": "bytes32" } ], "name": "settleBet", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" } ]
const contractAddress = '0x0'; 

 window.onload = function() {
 	//Determine whether metamask is injected
    if (typeof web3 === 'undefined') {
        document.getElementById('meta-mask-required').innerHTML = 'You need <a href="https://metamask.io/">MetaMask</a> browser plugin'
      }
    }

//Test function to call FaireumDice contract placeBet method
function placeBet() {

	let contract = new web3.eth.Contract(abi, contractAddress);

	//modulo and betID todo
	contract.methods.placebet('2','1').call().then(function(balance) {

		console.log('betPlaced');
	})
	.on('receipt', function(rec){ 
		console.log(rec);
	});
	.on('error', function(err) { 
	        console.error(err);
	})
	.on('transactionHash', console.log);
 
}

function settleBet() {

	let contract = new web3.eth.Contract(abi, contractAddress);

	//reveal and blockhash todo
	contract.methods.settleBet('2','1').call().then(function(balance) {

		console.log('bet settled info');
	})
	.on('receipt', function(rec){ 
		console.log(rec);
	});
	.on('error', function(err) { 
	        console.error(err);
	})
	.on('transactionHash', console.log);
}

//Test function to send eth
function sendTest() {
      web3.eth.sendTransaction({
        from: web3.eth.coinbase,
        to: '',
        value: web3.toWei(document.getElementById("amount").value, 'ether')
      }, function(error, result) {
        if (!error) {
          document.getElementById('response').innerHTML = 'Success: <a href="https://ropsten.etherscan.io/tx/' + result + '"> View Transaction </a>'
        } else {
          document.getElementById('response').innerHTML = '<pre>' + error + '</pre>'
        }
    })
}
