#!/usr/bin/env bash

# This script is used to migrate local repository's remote origin from bitbucket url to github url.
# This script assumes that you have already created a repository on github with same name as bitbucket repository.

# Usage:
#  ./migrate-local.sh [options] path

# Options:
#   -h, --help      Show help message and exit
#   -s, --scan      Scan current directory for git repositories and migrate them
#   -d, --dry-run   Dry-run

# Arguments:
#   path            Path to the git repository to migrate or directory to scan

option_scan=false
option_dry_run=false
option_help=false
arg_path=""

# Set options_help=true if no arguments are passed
if [[ $# -eq 0 ]]; then
    option_help=true
else
    # Get options and arguments
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -h|--help)
                option_help=true
                ;;
            -s|--scan)
                option_scan=true
                ;;
            -d|--dry-run)
                option_dry_run=true
                ;;
            *)
                arg_path="$key"
                ;;
        esac

        # Remove the processed argument from the argument list
        shift
    done
fi


# Show help message if option_help is true
if [[ $option_help == true ]]; then
    echo "Usage:"
    echo "  ./migrate-local.sh [options] path"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show help message and exit"
    echo "  -s, --scan      Scan current directory for git repositories and migrate them"
    echo ""
    echo "Arguments:"
    echo "  path            Path to the git repository to migrate or directory to scan"
    exit 0
fi

# For debugging
# echo "option_scan=$option_scan, arg_path=$arg_path"
# exit 0

# Define constants
BITBUCKET_ORG="corporate-data-league"
GITHUB_ORG="cdqag"

# Get current working directory
cwd=$(pwd)


# Function to migrate a git repository by it's path
migrate_repository() {
    directory_path="$1"

    if [[ ! -d "$directory_path" ]]; then
        echo "Directory $directory_path does not exists."
        return
    fi

    # Get the directory name from the path
    directory=$(basename $directory_path)

    echo "Migrating $directory ($directory_path)"
    cd $directory_path

    # Check if this is a git repository
    if [ ! -d ".git" ]; then
        echo "  Not a git repository"
        cd "$cwd"
        return
    fi

    # Find the repository name in current remote origin
    current_remote=$(git remote get-url origin)

    # Get the repository name from the current remote
    repository_name=$(echo $current_remote | cut -d'/' -f2 | cut -d'.' -f1)

    # Get the repository username from the current remote
    repository_username=$(echo $current_remote | cut -d'/' -f1 | cut -d':' -f2)

    # Check if the repository username is same as bitbucket username
    if [ "$repository_username" != "$BITBUCKET_ORG" ]; then
        echo "  Not a bitbucket repository owned by CDQ"
        cd "$cwd"
        return
    fi

    echo "  Current remote origin: $current_remote"
    echo "  Repository name: $repository_name"

    new_remote="git@github:$GITHUB_ORG/$directory.git"
    echo "  Setting remote origin: $new_remote"
    
    # Run the command if option_dry_run is false
    if [[ $option_dry_run == false ]]; then
        git remote set-url origin "$new_remote"
    else
        echo "  Dry-run"
    fi

    echo "  Done"
    cd "$cwd"
}


# If option_scan is true, scan current directory for git repositories and migrate them
if [[ $option_scan == true ]]; then
    # Scan arg_path for git repositories
    directories=$(find "$arg_path" -maxdepth 1 -type d | sort)

    # Remove first path from $directories
    directories=$(echo $directories | cut -d' ' -f2-)

    # Iterate over each directory and migrate it's remote origin
    for directory_path in $directories
    do
        migrate_repository "$directory_path"
    done

else
    # Migrate the repository by it's path
    migrate_repository "$arg_path"
fi

echo "Finished"
