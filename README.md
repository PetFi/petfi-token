# PFT ERC20 token

Token for PetFi NFT marketplace

## Tokenomics:
- Name: PFT, Symbol: PetFi
- Total supply: 248,012,500
- Token sale price: 0.11$

- Minting of new tokens with a capped supply
- Burning of tokens with a capped supply
- Transfer to a specific wallet address
- Ownership transfer to a specific wallet address
- Admin of the smart contract through Ehterscan
- Transaction fee:
- 2% to token holders
- 2% to project: The 2% for the project is to cover liquidity and marketing etc
- 1% burn


# How to deploy token  

    $ npm install @openzeppelin/contracts
    $ npm install @truffle/hdwallet-provider
    $ truffle deploy --network rinkeby
    $ truffle verify ChengToken --network rinkeby

