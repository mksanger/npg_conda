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
    [-o <owner name>]
    [-g <github repo>]
    [-k <github token>]
    [-t <gitlab token>]
    [-i <project id>]
    [-h]
EOF
}

while getopts "hl:n:o:g:k:t:i:" option; do
    case "$option" in
        h)
            usage
            exit 0
            ;;
        l)
            gitlab_repo="$OPTARG"
            ;;
        n)
            repo_name="$OPTARG"
            ;;
        o)
            owner_name="$OPTARG"
            ;;
        g)
            github_repo="$OPTARG"
            ;;
        k)
            github_token="$OPTARG"
            ;;
        t)
            gitlab_token="$OPTARG"
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

# update devel
git clone $github_repo $repo_name
cd $repo_name
git checkout devel

git push -f $gitlab_repo devel


prs=$(curl --header "Authorization: bearer $github_token" --request POST -d " \
              { \
                \"query\": \"query { \
                  repository (name: \\\"${repo_name}\\\", owner: \\\"${owner_name}\\\") { \
                    pullRequests (first:100, states:OPEN) { \
                      nodes{ \
                        title, \
                        headRepository{ \
                          url \
                        }, \
                        branch: headRefName, \
                        sha: headRefOid \
                      } \
                    } \
                  } \
                }\" \
              }" \
              https://api.github.com/graphql |
    jq '.[].repository.pullRequests.nodes[]')

mrs=$(curl --header "PRIVATE-TOKEN: $gitlab_token" "https://gitlab.internal.sanger.ac.uk/api/v4/projects/${project_id}/merge_requests?state=opened")
current_mrs=()

for pr in $(echo $prs| jq -c '{title:.title, sha:.sha, url:.headRepository.url, branch:.branch}' | sed 's/ /_/g' || "");
do
    present=0
    for mr in $(echo $mrs | jq -c '.[] | {title:.title, sha:.sha}' | sed 's/ /_/g' || "");
    do
        if [ $(echo $pr | jq '.sha') == $(echo $mr | jq '.sha') ]
        then
            current_mrs+=($(echo $mr | jq '.title' | sed 's/"//g'))
            present=2
            break
        elif  [ $(echo $pr | jq '.title') == $(echo $mr | jq '.title') ]
        then
            current_mrs+=($(echo $mr | jq '.title' | sed 's/"//g'))
            present=1
            break
        fi
    done

    if [ $present == 2 ]
       then
            continue
    fi
    
    # pull source 
    source=$(echo $pr | jq '.url' | sed 's/"//g')
    branch=$(echo $pr | jq '.branch' | sed 's/"//g')
    git remote add fork "$source"
    git fetch fork
    git checkout --track fork/"$branch"

    # push to branch on gitlab (provides branch for new mr or automatically updates old mr)
    git push -f "$gitlab_repo" "$branch"
    git remote remove fork
    
    if [ $present == 0 ]
    then
        title=$(echo "$pr" | jq '.title' | sed 's/"//g')
        # create merge request
        curl --header "PRIVATE-TOKEN: $gitlab_token" --header "Content-Type: application/json" --request POST -d " \
             { \
                \"id\": $project_id, \
                \"source_branch\": \"$branch\", \
                \"target_branch\": \"devel\", \
                \"title\": \"$title\" \
             } "\
             "https://gitlab.internal.sanger.ac.uk/api/v4/projects/${project_id}/merge_requests"
    fi
done

#Check for old mrs in gl
for mr in $(echo "$mrs" | jq -c '.[] | {title:.title, iid:.iid, branch:.source_branch}' | sed 's/ /_/g');
do
    current=0
    for current_mr in ${current_mrs[*]-""} # default is "" to avoid unbounded variable errors
    do
        if [ $(echo "$mr" | jq '.title' | sed 's/"//g') == $current_mr ]
        then
            current=1
            break
        fi
    done
    
    if [ "$current" -eq 0 ]
    then
        # close mr
        curl --request PUT --header "PRIVATE-TOKEN: $gitlab_token" --header "Content-Type:application/json" -d "{\"state_event\": \"close\"}" "https://gitlab.internal.sanger.ac.uk/api/v4/projects/${project_id}/merge_requests/$(echo $mr | jq '.iid' | sed 's/\"//g')"

        # delete branch
        git push -d $gitlab_repo $(echo $mr | jq '.branch' | sed 's/"//g')
    fi
done

cd ..
rm -rf npg_conda
        
