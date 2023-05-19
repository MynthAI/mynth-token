#!/bin/bash

# This bash script creates a JSON file containing metadata for
# adding a token to the Cardano Off-Chain Metadata Registry
# (https://github.com/cardano-foundation/cardano-token-registry).
# The script gathers necessary information, formats it according
# to the registry's guidelines, and outputs a JSON file ready for
# submission.
#
# To update existing metadata, pass `--changed` followed by a
# list of fields that have been changed. For example:
#
#    bash register.sh logo description

set -e

string_in_array() {
  local string="$1"
  shift
  local array=("$@")

  for element in "${array[@]}"; do
    if [[ "$element" == "$string" ]]; then
      return 0
    fi
  done

  return 1
}

name=$(yq '.name' metadata.yaml)
description=$(yq '.description' metadata.yaml)
ticker=$(yq '.ticker' metadata.yaml)
url=$(yq '.url' metadata.yaml)
logo=$(yq '.logo' metadata.yaml)
decimals=$(yq '.decimals' metadata.yaml)

encodedName=$(echo -n "$name" | xxd -ps)
policyID=$(cat policy/policy.id)
token="$policyID$encodedName"

# Get the user-specified fields that have changed, if any
changed=()
if [ "$1" == "--changed" ]; then
  shift
  changed=("$@")
fi

n="Null"
token-metadata-creator entry --init "$token" \
  --name "$(if string_in_array name "${changed[@]}"; then echo "$n"; else echo "$name"; fi)" \
  --description "$(if string_in_array description "${changed[@]}"; then echo "$n"; else echo "$description"; fi)" \
  --ticker "$(if string_in_array ticker "${changed[@]}"; then echo "$n"; else echo "$ticker"; fi)" \
  --url "$(if string_in_array url "${changed[@]}"; then echo "$n"; else echo "$url"; fi)" \
  --logo "$(if string_in_array logo "${changed[@]}"; then echo "n.png"; else echo "$logo"; fi)" \
  --decimals "$(if string_in_array decimals "${changed[@]}"; then echo "$n"; else echo "$decimals"; fi)" \
  --policy policy/policy.script

token-metadata-creator entry "$token" \
  --name "$name" \
  --description "$description" \
  --ticker "$ticker" \
  --url "$url" \
  --logo "$logo" \
  --decimals "$decimals" \
  --policy policy/policy.script

token-metadata-creator entry "$token" -a policy/policy.skey
token-metadata-creator entry "$token" --finalize
