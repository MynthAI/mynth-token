# Mynth Token Minting

This project includes a set of bash scripts that use `cardano-cli` to
mint the Mynth Token, a Cardano native token. These scripts automate the
token minting process.

## Prerequisites

  - Installed and configured Cardano node and cardano-cli

## Quick Start

1.  Mint the token:
    
        bash mint.sh

2.  Send ADA (e.g., 20) to the address displayed by the script.

3.  After funding the wallet with ADA, run `mint.sh` again:
    
        bash mint.sh

4.  Enter “MINT” and press enter to mint the token.

5.  After the token is minted, you can send it to another wallet using
    `send.sh`:
    
        bash send.sh [DESTINATION]

6.  When the token is ready, register it with the [Cardano Off-Chain
    Metadata
    Registry](https://github.com/cardano-foundation/cardano-token-registry)
    using `register.sh`:
    
        bash register.sh

7.  Copy or move the output JSON file to the cardano-token-registry
    repository and follow their steps to submit the registration.

## Scripts

  - `mint.sh`: Main script for minting tokens
  - `send.sh`: Sends minted tokens to a destination wallet
  - `register.sh`: Generates the metadata registration file

## Configuring the Token

This repository is set up to mint the Mynth Token. You can configure the
token to mint by modifying the `metadata.yaml` file. Update the details
in this file to change the token you want to mint.
