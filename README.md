# schwap-contracts

anvil -f "https://eth.llamarpc.com"

forge script script/Deploy.s.sol:Deploy -f http://localhost:8545 \ --private-key $PRIVATE_KEY0 --broadcast
