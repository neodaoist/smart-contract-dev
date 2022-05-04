# Basic NFT contract deploying, minting, and checking ownerOf
forge create NFT --rpc-url=$RINKEBY_RPC_URL --private-key=$PRIVATE_KEY --constructor-args "Lyfe NFT" "LYFE"
cast send --rpc-url=$RINKEBY_RPC_URL <contractAddress> "mintTo(address)" <eoaAddress> --private-key=$PRIVATE_KEY
cast call --rpc-url=$RINKEBY_RPC_URL --private-key=$PRIVATE_KEY <contractAddress> "ownerOf(uint256)" 1
