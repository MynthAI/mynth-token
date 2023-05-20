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
#     bash register.sh logo description

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

# Get the user-specified fields that have changed, if any
changed=()
if [ "$1" == "--changed" ]; then
    shift
    changed=("$@")
fi

get_metadata_value() {
    local field="$1"
    local default_value="$2"
    if string_in_array "$field" "${changed[@]}"; then
        echo "$default_value"
    else
        yq ".$field" metadata.yaml
    fi
}

name=$(get_metadata_value "name" "Null")
description=$(get_metadata_value "description" "Null")
ticker=$(get_metadata_value "ticker" "Null")
url=$(get_metadata_value "url" "Null")
logo=$(get_metadata_value "logo" "n.png")
decimals=$(get_metadata_value "decimals" "Null")

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

token-metadata-creator entry "$token" \
    --name "$(yq '.name' metadata.yaml)" \
    --description "$(yq '.description' metadata.yaml)" \
    --ticker "$(yq '.ticker' metadata.yaml)" \
    --url "$(yq '.url' metadata.yaml)" \
    --logo "$(yq '.logo' metadata.yaml)" \
    --decimals "$(yq '.decimals' metadata.yaml)" \
    --policy policy/policy.script

token-metadata-creator entry "$token" -a policy/policy.skey
token-metadata-creator entry "$token" --finalize
