# Basic NFT contract deploying, minting, and checking ownerOf
forge create NFT --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args "Lyfe NFT" "LYFE"
cast send --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "mintTo(address)" <eoaAddress>
cast send --rpc-url=$L2_RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "mintTo(address)" <eoaAddress> --legacy --value 0.08ether
cast call --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "ownerOf(uint256)" 1
cast call --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "tokenURI(uint256)" 1
cast call --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "balanceOf(address)" <eoaAddress>

# forge
## General commands

## Project commands

## Build commands

## Test commands
forge test
forge test -vvv
forge test --match-contract <testSuiteName>
forge test --fork-url <rpcURL> --fork-block-number <blockNumber>

## Deploy commands
forge script script/NFT.s.sol:NFTScript --rpc-url $RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
forge create <path>:<contractName> --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY
forge verify-contract --compiler-version "<compilerVersion>" <contractAddress> <path>:<contractName> "<etherscanKey>" --chain-id=<chainId>
# v0.8.11+commit.d7f03943
# v0.8.13+commit.abaa5c0e
# v0.8.17+commit.8df45f5f

## Utility commands

# cast

# anvil
