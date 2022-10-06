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
forge create <contractFile> --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY
forge verify-contract --compiler-version "<compilerVersion>" <contractAddress> <contractFile> "<etherscanKey>" --chain-id=<chainId>

## Utility commands

# cast

# anvil
