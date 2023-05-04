# This bash script creates a JSON file containing metadata for
# adding a token to the Cardano Off-Chain Metadata Registry
# (https://github.com/cardano-foundation/cardano-token-registry).
# The script gathers necessary information, formats it according
# to the registry's guidelines, and outputs a JSON file ready for
# submission.

set -e

name=$(yq '.name' metadata.yaml)
description=$(yq '.description' metadata.yaml)
ticker=$(yq '.ticker' metadata.yaml)
url=$(yq '.url' metadata.yaml)
logo=$(yq '.logo' metadata.yaml)
decimals=$(yq '.decimals' metadata.yaml)

encodedName=$(echo -n "$name" | xxd -ps)
policyID=$(cat policy/policy.id)
token="$policyID$encodedName"

token-metadata-creator entry --init "$token" \
    --name "$name" \
    --description "$description" \
    --ticker "$ticker" \
    --url "$url" \
    --logo "$logo" \
    --decimals "$decimals" \
    --policy policy/policy.script

token-metadata-creator entry "$token" -a policy/policy.skey
token-metadata-creator entry "$token" --finalize
