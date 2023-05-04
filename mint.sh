# This bash script mints a Cardano native token. By default, it
# operates on the mainnet. Pass the optional "testnet" flag as
# an argument to mint the token on the Cardano preview testnet.

set -e

network="--mainnet"
if [ "$1" == "testnet" ]; then
    network="--testnet-magic 2"
fi

name=$(yq '.name' metadata.yaml | tr -d '\n' | xxd -ps)
decimals=$(yq e '.decimals' metadata.yaml)
supply=$(yq e '.supply' metadata.yaml)
amount=$(echo "scale=$decimals; $supply * 10^$decimals" | bc)

expiration=60
fee=300000
output=0

if [ ! -e "payment.vkey" ] && [ ! -e "payment.skey" ]; then
  cardano-cli address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey
fi

cardano-cli address build \
    --payment-verification-key-file payment.vkey \
    --out-file payment.addr $network

address=$(cat payment.addr)

echo "Fund address: $address"

read -r tx funds <<< "$(
    cardano-cli query utxo --address "$address" $network |
    grep lovelace |
    grep -v 'lovelace + [0-9]' |
    awk 'BEGIN {max_lovelace = 0} {
        if ($3 > max_lovelace) {
            max_lovelace = $3; utxo_id = $1; txix = $2
        }} END {
            if (utxo_id != "") {
                printf "%s#%s %s", utxo_id, txix, max_lovelace
            }
        }')"
if [[ -z "${tx}" ]]; then
  echo "Run again after funding address"
  exit 1
fi

cardano-cli query protocol-parameters $network > protocol.json

mkdir -p policy

if [ ! -e "policy/policy.vkey" ] && [ ! -e "policy/policy.skey" ]
then
    cardano-cli address key-gen \
        --verification-key-file policy/policy.vkey \
        --signing-key-file policy/policy.skey
fi

# Ensure only we can mint the token
keyHash=$(cardano-cli address key-hash \
    --payment-verification-key-file policy/policy.vkey)

# Expire minting policy shortly after creation
beforeSlot=$(
    cardano-cli query tip $network | \
    jq '.slot + ($expiration | tonumber)' \
    --arg expiration "$expiration" --raw-output)

# Create the policy ID
jq --arg keyHash "$keyHash" \
    --arg beforeSlot "$beforeSlot" '
    .scripts |= map(
        if .keyHash then .keyHash = $keyHash else . end |
        if .slot then .slot = ($beforeSlot | tonumber) else . end
    )' minting-policy.json > policy/policy.script
policyID=$(cardano-cli transaction policyid \
    --script-file policy/policy.script)
echo -n "$policyID" > policy/policy.id

cardano-cli transaction build-raw \
  --fee "$fee" \
  --tx-in "$tx" \
  --tx-out "$address+$output+$amount $policyID.$name" \
  --mint "$amount $policyID.$name" \
  --minting-script-file policy/policy.script \
  --invalid-hereafter "$beforeSlot" \
  --out-file matx.raw

# Calculate fee then rebuild transaction
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file matx.raw \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 2 \
    $network \
    --protocol-params-file protocol.json | cut -d " " -f1)
output=$((funds - fee))
cardano-cli transaction build-raw \
  --fee "$fee" \
  --tx-in "$tx" \
  --tx-out "$address+$output+$amount $policyID.$name" \
  --mint "$amount $policyID.$name" \
  --minting-script-file policy/policy.script \
  --invalid-hereafter "$beforeSlot" \
  --out-file matx.raw

cardano-cli transaction sign \
    --signing-key-file payment.skey \
    --signing-key-file policy/policy.skey \
    $network \
    --tx-body-file matx.raw \
    --out-file matx.signed

echo "Ready to mint. Enter MINT to continue:"
read -r user_input

if [ "$user_input" != "MINT" ]; then
  exit
fi

cardano-cli transaction submit \
    --tx-file matx.signed \
    $network
