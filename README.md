# Sugar Contracts

Smart contracts for Sugar, a Web3-native platform empowering streamers and communities to connect, collaborate, and monetize transparently.

## ⚙️ Tech Stack

- **Foundry** – Fast, modular testing and deployment framework for Solidity  
- **Forge Std** – Testing utilities and cheatcodes  
- **OpenZeppelin Contracts** – Secure, audited smart contract libraries

## 🔨 Setup

1. Install Foundry:

   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
    ````

1. Install dependencies:

   ```bash
   npm install
   ```

## 🚀 Scripts

- Run tests:

  ```bash
  forge test
  ```

- Run a script (e.g., deploy):

  ```bash
  forge script script/SugarDonation.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
  ```

## 👥 Team

Built with ❤️ by:

- **Rei Yan**
- **Jo**
- **Rama**

Part of the Sugar project: [github.com/sugar-space](https://github.com/sugar-space)
