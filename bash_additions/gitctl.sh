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
    local repo
    local org
    if [ -z $1 ]; then
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            gito 
            echo "Not a git repository."
            return 1
        fi
        repo=$(basename "$PWD")
        org=$(basename "$(dirname "$PWD")")
    fi
    if [[ $1 == *"/"* ]]; then
        org=$(echo "$1" | awk -F/ '{print$1}')
        repo=$(echo "$1" | awk -F/ '{print$2}')
    else
        org=$(ls -d $GIT_ROOT_DIR/*/ | fzf)
        if [ -z $org ]; then
            echo "org cannot be empty"
            return
        fi
        repo=$(ls -d $org/*/ | fzf)
        if [ -z $repo ]; then
            echo "repo cannot be empty"
            return
        fi
    fi
    if [[ -z $org || -z $repo ]]; then
        echo "org and repo cannot be empty"
        return 1
    fi
    echo "Opening repo $org/$repo in browser..."
    google-chrome https://github.com/$org/$repo
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

