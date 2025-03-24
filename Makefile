.PHONY: test
test:
	forge test

.PHONY: debug
debug:
	forge test -vv

.PHONY: trace
trace:
	forge test -vvvv

.PHONY: coverage
coverage:
	forge coverage

.PHONY: deploy
deploy:
	set +a; \
	source .env; \
	set -a; \
	forge script \
	script/SugarDonation.s.sol:DeploySugarDonation \
	--rpc-url $$RPC_URL \
	--private-key $$PRIVATE_KEY \
	--broadcast \
	--verify \
	--etherscan-api-key $$ETHERSCAN_API_KEY



.PHONY: install
install:
	forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts --no-commit