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

.PHONY: deploy-bs
deploy-bs:
	set +a; \
	source .env; \
	set -a; \
	forge script \
	script/SugarDonation.s.sol:DeploySugarDonation \
	--rpc-url $$RPC_URL \
	--private-key $$PRIVATE_KEY \
	--broadcast \
	--optimize \
	--optimizer-runs 100 \
	--skip-simulation \
	--verify \
	--verifier-url https://sepolia-blockscout.lisk.com/api \
	--verifier blockscout

.PHONY: install
install:
	forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts --no-commit