#!/bin/bash

# TODO: turn this into gitctl lmao

# gitlatestchange(){
#     watch="$1"
#     date_tracker_file=/tmp/track-"${watch//\//_}".txt
#     workingBranch=$(git branch | awk '/\*/{print$2}')
#     echo "Updating all branches..."
#     for branch in $(gitallbranches); do
#         git switch $branch 2>/dev/null && git pull 2>/dev/null
#     done
#     echo "Updated $(gitallbranches | wc -l) branches."
#     echo "Finding latest change in all branches..."
#     for branch in $(gitallbranches); do
#         git switch $branch 2>/dev/null
#         if [[ ! -z "$(readlink -e "$watch" 2>/dev/null)" ]]; then
#             echo "Grabbing change from $branch..."
#             echo "$branch:$(git log -1 --format="%ai" -- "$watch" | awk '{print$1}')" >> $date_tracker_file
#         fi
#     done
#     currentLatestChange=$(head -n 1 $date_tracker_file)
#     echo "Computing latest change..."
#     for line in $(tail -n +2 $date_tracker_file); do
#         currLatestBranch=$(awk -F: '{print$1}' <<< $currentLatestChange)
#         currLatestDate=$(date -d $(awk -F: '{print$2}' <<< $currentLatestChange) +"%Y%m%d")
#         if [ $(date -d $(awk -F: '{print$2}' <<< $line) +"%Y%m%d") -ge $currLatestDate ]; then
#             currentLatestChange=$line
#         fi
#     done
#     echo "Current latest change for '$watch' is in $currLatestBranch at $currLatestDate"
#     rm $date_tracker_file
#     git switch $workingBranch
# }

gitallbranches(){
    git branch | awk '{if ($1 == "*"){print$2}else{print$1}}'
}

gitupdate(){
    git add .
    if [[ $(git status) == *"nothing to commit"* ]]; then
        echo "No local changes. skipping repo update"
    else
        git commit -m "Update repo"
            git push -u
            fi
}

gitm() {
    git commit -m "$*"
}

gita() {
    git add .
}

gitcurrentbranch(){
    branch=$(git branch | awk '/\*/{print$2}')
    echo -n $branch | copy
    echo "$branch copied to clipboard"
}

gito(){
    workdir=$PWD
    cd $GIT_ROOT_DIR
    org=$(ls -d */ | fzf)
    if [ -z $org ]; then
        echo "org cannot be empty"
        return
    fi
    cd $org
    repo=$(ls -d */ | fzf)
    if [ -z $repo ]; then
        echo "repo cannot be empty"
        return
    fi
    google-chrome https://github.com/$org${repo/\//}
    cd $workdir
}

gitchromeopen(){
    local input="$1"
    local orgrepo
    # flat list of org/repo across all orgs, built once for scanning/fzf
    local all_repos
    all_repos=$(find "$GIT_ROOT_DIR" -mindepth 2 -maxdepth 2 -type d -printf '%P\n')

    if [ -z "$input" ]; then
        orgrepo=$(echo "$all_repos" | fzf)
    else
        local exact_matches
        exact_matches=$(echo "$all_repos" | awk -F/ -v r="$input" '$2==r')
        if [ "$(echo "$exact_matches" | grep -c .)" -eq 1 ]; then
            orgrepo=$exact_matches
        else
            local partial_matches
            partial_matches=$(echo "$all_repos" | grep "$input")
            local pcount
            pcount=$(echo "$partial_matches" | grep -c .)
            if [ "$pcount" -eq 1 ]; then
                orgrepo=$partial_matches
            elif [ "$pcount" -gt 1 ]; then
                orgrepo=$(echo "$partial_matches" | fzf)
            else
                echo "No matches found for '$input'"
                return 1
            fi
        fi
    fi

    if [ -z "$orgrepo" ]; then
        echo "org/repo cannot be empty"
        return 1
    fi
    echo "Opening repo $orgrepo in browser..."
    google-chrome "https://github.com/$orgrepo"
}

gitcreatepr(){
    branch=$(git branch | awk '/\*/{print$2}')
    gh pr create --base $(git remote show origin | sed -n '/HEAD branch/s/.*: //p') --head $branch --title "${branch/-/ }" --body "PR for $branch" | copy
    gh pr view --web
}

# gitcommit(){
#     if git branch | awk '/\*/{print$2}' | grep -q 'main\|master'; then
#         new_branch=$(zenity --entry --title="New Branch" --text="You are on the main or master branch. Enter new branch name:" --entry-text "XOPS-0000-$(date +%H-%M)-new-feature")
#         git checkout -b "$new_branch"
#         git push --set-upstream origin "$new_branch"
#     fi
#     ticket=$(git branch | awk '/\*/{print$2}' | awk -F- '{printf "%s-%s",$1,$2}')
#     if [ -z "$1" ]; then
#         message=$(zenity --entry --title="Commit message" --text="Enter commit message:")
#     else
#         message="$*"
#     fi
#     git add .
#     git commit -m "$ticket feat: $message"

#     read -p "Push to remote? (y/n): " -n 1 -r
#     echo
#     if [[ $REPLY =~ ^[Yy]$ ]]; then
#         git push
#     fi

#     read -p "Create PR? (y/n): " -n 1 -r
#     echo
#     if [[ $REPLY =~ ^[Yy]$ ]]; then
#         gh pr create --base $(git remote show origin | sed -n '/HEAD branch/s/.*: //p') --head $new_branch --title "${new_branch/-/ }" --body "PR for $new_branch" | copy
#         gh pr view --web
#     fi
# }

# gitmergemain(){
#     origin_branch=$(git branch | awk '/\*/{print$2}')
#     git switch main
#     git pull
#     git switch $origin_branch
#     git merge main
# }

# gitsetbranch(){
#     git push --set-upstream origin "$(git branch | awk '/\*/{print$2}')"
# }

# gitbranchAll(){
#     for b in `git branch -r | grep -v -- '->'`; do
#         git branch --track ${b##origin/} $b
#     done
# }

# gitclearlocalbranches(){
#     git fetch -p
#     git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D
# }

gitpullall(){
    workdir=$PWD
    cd $GIT_ROOT_DIR
    org=$(ls -d */ | fzf)
    if [ -z $org ]; then
        echo "org cannot be empty"
        return
    fi
    cd $org
    for repo in ./*; do
        if [ -d $repo ]; then
            cd "$repo"
            if [ "$(git branch | awk '/\*/{print$2}')" == 'main' ]; then
               git pull
            fi
            cd ../
        fi
    done
    cd $workdir
}

