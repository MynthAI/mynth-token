# This bash script sends all ADA and tokens from a source wallet
# to a specified destination address by utilizing the Cardano
# CLI. It retrieves the wallet's UTXOs, calculates the
# transaction fees, and constructs a transaction to transfer the
# entire balance, including all native tokens, to the destination
# address.

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <address>"
    echo "Please provide an address as an argument."
    exit 1
fi

network="--mainnet"
if [ "$2" == "testnet" ]; then
    network="--testnet-magic 2"
fi

address=$(cat payment.addr)
fee=300000

input=$(
    cardano-cli query utxo --address "$address" $network |
    grep lovelace |
    head -n1 |
    sed 's/ + TxOutDatumNone//'
)

if [[ -z "${input}" ]]; then
  echo "No funds in the wallet"
  exit 1
fi

tx=$(awk '{print $1 "#" $2}' <<< "$input")
output=$(awk '{print $3}' <<< "$input")
tokens=$(
    awk '{for (i=5; i<=NF; i++) printf $i " "; print ""}' <<< "$input" |
    sed 's/ //1'
)

cardano-cli transaction build-raw \
    --fee "$fee" \
    --tx-in "$tx" \
    --tx-out "$1+$output$tokens"  \
    --out-file rec_matx.raw

# Calculate fee then rebuild transaction
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file rec_matx.raw \
    --tx-in-count 1 \
    --tx-out-count 2 \
    --witness-count 1 \
    $network \
    --protocol-params-file protocol.json | cut -d " " -f1)
output=$((output - fee))

cardano-cli transaction build-raw \
    --fee "$fee" \
    --tx-in "$tx" \
    --tx-out "$1+$output$tokens"  \
    --out-file rec_matx.raw

cardano-cli transaction sign \
    --signing-key-file payment.skey \
    $network \
    --tx-body-file rec_matx.raw \
    --out-file rec_matx.signed

echo "Ready to send. Enter SEND to continue:"
read -r user_input

if [ "$user_input" != "SEND" ]; then
  exit
fi

cardano-cli transaction submit \
    --tx-file rec_matx.signed \
    $network
