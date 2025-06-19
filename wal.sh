#!/bin/bash

: '
    Theme UPDATE script
'

if [ -z "$1" ]; then
  clear;
  echo '

Available commands are:

  > help

  > theme-init                    # Initialize project folders
  > simple-rollout                # Copy files, commit and push to all stores
  > simple-rollout-test           # The same as simple-rollout, but does not commit or push
  > copy-file dir/file.ext        # Copy a single file to all stores
  > copy-files                    # Copy all files to all stores, excluding JSON files
  > copy-files-all                # Copy all files to all stores, including JSON files
  > shopify-pull                  # Pull the latest content from Shopify for all stores
  > git-restore                   # Restore/Remove all files to the last committed state
  > git-pull                      # Pull the latest changes from Git for all stores
  > git-reset                     # Reset all stores to the last committed state in Git
  > git-push                      # Push all changes to Git for all stores
  > git-push-force                # Force push all changes to Git for all stores
  > git-commit                    # Commit all changes to Git for all stores
  > git-rollback                  # Rollback the last commit for all stores
  > git-rollback-local            # Rollback the last commit for all stores locally
  > git-rollback-remote           # Rollback the last commit for all stores remotely
  > git-log                       # Show last 2 commits

  Example >> sh '$0' help
  
  ';
  exit;

elif [[ "$1" == "help" ]]; then
  clear;
  echo '
############################################################################################################

                                    !!! MUST READ !!!
                                            -
    Please use this as a guide, BUT be sure to understand what it is exactly you are doing

############################################################################################################

  1. [ sh '$0' git-reset && sh '$0' git-pull ] Generally, the first thing you would want
  to do is to ensure each of the local theme is up to date with Git.

  2. [ sh '$0' shopify-pull ] You would then want to get the latest content from Shopify.
  However, this should technically be the same as git-pull, since it is connected to Git.
    - If changes are detected, run [ sh '$0' git-commit ] to save it.

  3. [ sh '$0' copy-files ] Next, you would want to copy the core theme files. This command will
  create a snapshot of the current state of the files into a ZIP file, just in case. This should all
  be non JSON files.

  4. Review. You should review if all files have been copied correctly.

  5. [ sh '$0' git-commit ] Commit the changes to each of the repo/branch. Keep in mind that
  this still does not include any content updates made within the Theme Customiser

  6. [ sh '$0' copy-files-all ] This step can be skipped if there are no updates made to the
  Theme Customiser. In theory, the changes are all JSON content.
    - Review any content changes made. Sometimes a manual merge is required.
    - [ sh '$0' git-commit ] Run another git commit to save the changes. If you need to
    restart the process, use the ZIP backup file created in step 3 or 6.

  7. [ sh '$0' git-push ] This will push all changes to git, which in turn will push to Shopify

############################################################################################################
  
  ';
  exit;

elif [[ "$1" == "snapshot" ]]; then
  zip -r "$(date +%s).zip" . -x "./*.zip"; # Create backup
  exit;

elif [[ "$1" == "theme-init" ]]; then
  git clone --depth=1 --branch="client-preview" git@github.com:BA-Creative/wearelikewise.git ./client-preview;

fi

stores=("int" "au" "nz" "eu" "uk" "us" "ca" "jp")
for store in "${stores[@]}"
do
  echo '
  
  ---------------------------------------------------------------------------------
  # Store: '$store'
  ---------------------------------------------------------------------------------
  ' | tr '[:lower:]' '[:upper:]';
  current_dir="${PWD}/${store}/"
  continue;

  case $1 in

    "simple-rollout")
      # GIT PULL
      git -C "${current_dir}" pull;

      # COPY WORK
      cp -r "${PWD}/client-preview/locales/" "${current_dir}/locales/"
      rsync -av --exclude='*/*.json' --exclude='.*' --exclude='*/.*' "${PWD}/client-preview/" "${current_dir}";

      # GIT COMMIT
      git -C "${current_dir}" rm -r --cached .;
      git -C "${current_dir}" add .;
      git -C "${current_dir}" commit -m "Theme sync";

      # GIT PUSH (PUBLISH)
      git -C "${current_dir}" push;
      ;;

    "simple-rollout-test")
      # GIT PULL
      git -C "${current_dir}" pull;

      # COPY WORK
      cp -r "${PWD}/client-preview/locales/" "${current_dir}/locales/"
      rsync -av --exclude='*/*.json' --exclude='.*' --exclude='*/.*' "${PWD}/client-preview/" "${current_dir}"
      ;;

    "copy-file")
      cp -r "${PWD}/client-preview/$2" "${current_dir}/$2"
      ;;

    "copy-files")
      zip -r "$(date +%s)-${stores}.zip" "./${stores}" -x "./*.zip"; # Create backup
      cp -r "${PWD}/client-preview/locales/" "${current_dir}/locales/"
      rsync -av --exclude='*/*.json' --exclude='.*' --exclude='*/.*' "${PWD}/client-preview/" "${current_dir}"
      ;;

     "copy-files-all")
      zip -r "$(date +%s)-${stores}.zip" "./${stores}" -x "./*.zip"; # Create backup
      rsync -av --exclude='.*' --exclude='*/.*' "${PWD}/client-preview/" "${current_dir}";
      ;;

    "shopify-pull")
      shopify theme pull --store="we-are-likewise-${store}" --live --path="${current_dir}";
      ;;

    "git-restore")
      git -C "${current_dir}" restore .;
      ;;

    "git-pull")
      git -C "${current_dir}" pull;
      ;;
    
    "git-reset")
      git -C "${current_dir}" reset --hard "origin/${store}";
      ;;

    "git-push")
      git -C "${current_dir}" push;
      ;;

    "git-push-force")
      git -C "${current_dir}" push --force;
      ;;

    "git-commit")
      git -C "${current_dir}" rm -r --cached .;
      git -C "${current_dir}" add .;
      git -C "${current_dir}" commit -m "Theme sync";
      ;;

    "git-rollback")
      git -C "${current_dir}" reset --hard HEAD~1
      git -C "${current_dir}" push origin HEAD:"${store}" --force
      ;;

    "git-rollback-local")
      git -C "${current_dir}" reset --hard HEAD~1
      ;;
    
    "git-rollback-remote")
      git -C "${current_dir}" push origin HEAD:"${store}" --force
      ;;

    "git-log")
      git -C "${current_dir}" log -2;
      ;;

    "theme-init")
      git clone --depth=1 --branch="${store}" git@github.com:BA-Creative/wearelikewise.git "${current_dir}";
      ;;

  esac

done