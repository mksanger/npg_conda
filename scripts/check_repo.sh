#! /bin/bash

set -e -u
branch="devel"

usage() {
    cat 1>&2 <<EOF
This script automates the running of gitlab pipelines when an upstream github 
repo is updated.

Usage: $(basename "$0")
    [-l <gitlab repo>]
    [-n <repo name>]
    [-b <branch name>]
    [-g <github repo>]
    [-t <token>]
    [-i <project id>]
    [-h]
EOF
}

while getopts "hl:n:b:g:t:i:" option; do
    case "$option" in
        h)
            usage
            exit 0
            ;;
        l)
            lab_repo="$OPTARG"
            ;;
        n)
            repo_name="$OPTARG"
            ;;
        b)
            branch="$OPTARG"
            ;;
        g)
            github_repo="$OPTARG"
            ;;
        t)
            token="$OPTARG"
            ;;
        i)
            project_id="$OPTARG"
            ;;
        *)
            usage
            echo "Invalid option!"
            exit 1
            ;;
    esac
done    
        


git clone $lab_repo $repo_name
cd $repo_name
git checkout $branch

git fetch $hub_repo

if [[ git diff $hub_repo/$branch ]]; then

    git pull $hub_repo $branch
    git push $lab_repo $branch

    curl --request POST -F token=$token -F ref=$branch "https://gitlab.internal.sanger.ac.uk/api/v4/projects/$project_id/trigger/pipeline"
fi

