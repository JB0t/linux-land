#!/bin/bash

# Requires: aws cli, fzf, aws-sso-util

alogin(){
    aws-sso-util login default
}

_aws_profile_list(){
    awk '/^\[profile /{print substr($2,1,length($2)-1)}' ~/.aws/config
}

_aws_profile_attr(){
    local profile="$1" key="$2"
    case "$key" in
        account_id|account)
            aws sts get-caller-identity --query Account --profile "$profile" --output text 2>/dev/null ;;
        name)
            echo "$profile" ;;
        *)
            awk -v p="[profile $profile]" -v k="$key" '
                $0==p{f=1;next} /^\[/{f=0}
                f{ n=split($0,a,/[[:space:]]*=[[:space:]]*/); gsub(/[[:space:]]/,"",a[1]); if(a[1]==k){print a[2];exit} }
            ' ~/.aws/config ;;
    esac
}

_aws_profiles_find(){
    local match_key="$1" match_value="$2" print_key="${3:-name}"
    local found=0
    while IFS= read -r profile; do
        local val
        val=$(_aws_profile_attr "$profile" "$match_key")
        if [ "$val" = "$match_value" ]; then
            _aws_profile_attr "$profile" "$print_key"
            found=1
        fi
    done < <(_aws_profile_list)
    return $((1 - found))
}

aprofile(){
    local select
    select=$(_aws_profile_list | fzf)
    if [ -z "$select" ]; then
        echo "Select empty, doing nothing."
        return
    fi
    export AWS_PROFILE="$select"
    echo "AWS profile set to $select."
}

ainfo(){
    local select
    select=$(_aws_profile_list | fzf)
    if [ -z "$select" ]; then
        echo "Select empty, doing nothing."
        return
    fi
    echo "Profile:    $select"
    echo "Account ID: $(_aws_profile_attr "$select" account_id)"
    echo "Region:     $(_aws_profile_attr "$select" region)"
}

alookup(){
    if [ -z "$1" ]; then
        echo "Usage: alookup <account-id>"
        return 1
    fi
    local results
    results=$(_aws_profiles_find account_id "$1")
    if [ -z "$results" ]; then
        echo "No profiles found for account $1"
        return 1
    fi
    echo "$results"
}
