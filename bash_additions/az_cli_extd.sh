#!/bin/bash

# Requires: az cli, fzf, chrome

# Open the Azure portal on a resource group or resource in the current subscription.
# No args: fzf over everything. With an arg: open the single match, or fzf over the matches.
# 'home' opens the portal landing page.
azchromeopen(){
    local input="$1"
    local tenant
    tenant=$(az account show --query tenantId -o tsv) || return 1

    if [ "$input" == "home" ]; then
        chrome "https://portal.azure.com/#@$tenant/home"
        return
    fi

    local all_resources
    all_resources=$(
        az group list --query "[].[name,'resourceGroup',id]" -o tsv
        az resource list --query "[].[name,type,id]" -o tsv
    ) || return 1

    local selection
    selection=$(echo "$all_resources" | column -t -s $'\t' -o $'\t' | fzf \
        --query "$input" \
        --select-1 \
        --exit-0 \
        --delimiter $'\t' \
        --with-nth 1,2 \
        --prompt="  az › " \
        --layout=reverse \
        --border=rounded \
        --border-label=" azchromeopen ")
    if [ -z "$selection" ]; then
        if [ -n "$input" ]; then
            echo "No matches found for '$input'"
            return 1
        fi
        echo "Doing nothing."
        return
    fi

    local name id
    name=$(awk -F'\t' '{print$1}' <<<"$selection" | xargs)
    id=$(awk -F'\t' '{print$3}' <<<"$selection" | xargs)
    echo "Opening $name in the Azure portal..."
    chrome "https://portal.azure.com/#@$tenant/resource$id"
}
