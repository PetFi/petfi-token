# PFT ERC20 token

Token for PetFi Platform

## Tokenomics:
- Name: PETFI TOKEN
- Symbol: PFT
- Decimals: 9
- Total supply: 248,012,500
- Token sale price: 0.10$

- Transaction fee:
- 2% fee auto moved to PETFI project wallet
- 2% fee auto distribute to all holders
- 1% fee burned forever

# How to deploy token  

    $ npm install @openzeppelin/contracts
    $ npm install @truffle/hdwallet-provider
    $ npm install truffle-plugin-verify
    $ truffle migrate --network mainnet
    $ truffle verify PFToken --network mainnet
