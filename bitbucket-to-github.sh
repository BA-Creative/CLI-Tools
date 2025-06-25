#!/bin/bash

EOL
    # Requires SSH authentication to Bitbucket with authorised public key
    # Requires SSH authentication to GitHub using >> gh auth login
    # Requires GitHub CLI (gh) installed for repository creation
EOF

# --- CONFIGURATION ---
BITBUCKET_USER="bacreative"
GITHUB_USER="BA-Creative"
# ----------------------

# Check if a repo name was provided
if [ -z "$1" ]; then
  echo "Error: No repository name provided."
  exit 1
fi

REPO="$1"

echo "Migrating: $REPO"

# Check if the destination directory already exists
if [ -d "$REPO.git" ]; then
  echo "$REPO.git exists, skipping Bitbucket clone."
  cd "$REPO.git" || exit 1
else
  git clone --mirror "git@bitbucket.org:$BITBUCKET_USER/$REPO.git" || { echo "Error: Clone failed."; exit 1; }
  cd "$REPO.git" || exit 1
fi

# Set GitHub as the new remote via SSH
git remote set-url origin "git@github.com:$GITHUB_USER/$REPO.git"

# Test SSH connection to GitHub
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"

# Check if GitHub repository exists by attempting to fetch
git ls-remote origin &> /dev/null
if [ $? -ne 0 ]; then
  if command -v gh &> /dev/null; then
    gh repo create "$GITHUB_USER/$REPO" --private --confirm || { echo "Error: gh repo create failed."; exit 1; }
  else
    echo "Error: GitHub repo does not exist and gh not installed."; exit 1
  fi
fi

# Push everything to GitHub
git push --mirror || { echo "Error: Push failed."; exit 1; }
cd ..
rm -rf "$REPO.git"
echo "Done: $REPO"
