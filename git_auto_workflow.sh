#!/bin/bash

# Check if a branch name is provided
if [ -z "$1" ]; then
  echo "Error: You must provide a branch name."
  exit 1
fi

BRANCH_NAME=$1

# Fetch latest branches from remote
git fetch origin

# Check out to the provided branch name
git checkout -b "$BRANCH_NAME" origin/"$BRANCH_NAME"

# Add all changes
git add .

# Commit the changes
echo "Enter a commit message: "
read COMMIT_MSG

git commit -m "$COMMIT_MSG"

# Push changes to the remote branch
git push origin "$BRANCH_NAME"

echo "Changes have been pushed to $BRANCH_NAME branch on GitHub."

