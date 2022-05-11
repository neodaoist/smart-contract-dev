# Basic NFT contract deploying, minting, and checking ownerOf
forge create NFT --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args "Lyfe NFT" "LYFE"
cast send --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "mintTo(address)" <eoaAddress>
cast send --rpc-url=$L2_RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "mintTo(address)" <eoaAddress> --legacy --value 0.08ether
cast call --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "ownerOf(uint256)" 1
cast call --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "tokenURI(uint256)" 1
cast call --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "balanceOf(address)" <eoaAddress>

## Etherscan verification

