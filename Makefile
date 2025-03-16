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
	forge create \
	--rpc-url $$RPC_URL \
	--private-key $$PRIVATE_KEY \
	--gas-limit 10000000 \
	--gas-price 10000000000 \
	--optimize \
	--optimizer-runs 200 \
	--broadcast \
	--verify \
	--verifier blockscout \
	--verifier-url $$VERIFIER_URL \
	src/SugarDonation.sol:SugarDonation \

.PHONY: install
install:
	forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts --no-commit