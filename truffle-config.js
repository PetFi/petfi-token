 const HDWalletProvider = require('@truffle/hdwallet-provider');
 const fs = require('fs');
 const mnemonic = fs.readFileSync(".secret").toString().trim();
 const { POLYGONSCAN_API_KEY} = require('./env.json');
 const { ETHERSCAN_API_KEY} = require('./env.json');
  
 module.exports = {
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {    
    etherscan: POLYGONSCAN_API_KEY
  },
  networks: {    
    matic: {
      provider: () => new HDWalletProvider(mnemonic, `https://rpc-mumbai.maticvigil.com`),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    maticmainnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://rpc-mainnet.maticvigil.com`),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    }    
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.2",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: false,
         runs: 200
       },
      //  evmVersion: "byzantium"
      }
    },
  },
};
