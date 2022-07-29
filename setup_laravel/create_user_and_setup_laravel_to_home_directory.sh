#!/bin/bash

type setfacl >/dev/null 2>&1 || { echo >&2 " acl is not installed.  Aborting."; exit 1; }

domainName='staging.katchup.tech'
user='esc'

function createSiteContainer () {
  local container=~/"apps/bashTest/example"
  mkdir -p $container
  echo $container
}

function createLaravelWorkspace () {
  local targetUser=$1
  local parentDirectory=$2
  local parentDirectory=$3
  local targetDirectory=""
  if cd "$container"
  then
    # create parent directory and set appropriate permissions for user and www-data
    mkdir -p "$parentDirectory"
    setfacl -m u:"$targetUser":rwx "$parentDirectory"
    setfacl -m d:u:"$targetUser":rwx "$parentDirectory"
    setfacl -m u:www-data:rx "$parentDirectory"
    setfacl -m d:u:www-data:rx "$parentDirectory"
    setfacl -m m:rwx "$parentDirectory"
    setfacl -m d:m:rwx "$parentDirectory"

    # create required directories for laravel application deployment
    mkdir -p "$parentDirectory"/{storage/{framework/{cache,cache/data,views,sessions,testing},app,app/public,logs},releases/d1/public}

    # Set storage directory rwx for both user and www-data
    targetDirectory="$container"/"$parentDirectory"/storage
    setfacl -m u:"$targetUser":rwx "$targetDirectory"
    setfacl -m d:u:"$targetUser":rwx "$targetDirectory"
    setfacl -m u:www-data:rwx "$targetDirectory"
    setfacl -m d:u:www-data:rwx "$targetDirectory"
    setfacl -m m:rwx "$targetDirectory"
    setfacl -m d:m:rwx "$targetDirectory"

    # create .env and set appropriate permissions
    if cd "$container"/"$parentDirectory"
    then
      touch .env
      setfacl -m u:"$targetUser":rwx .env
      setfacl -m u:www-data:r-- .env
    fi

    # Build a new release to test our setup
    targetDirectory="$container"/"$parentDirectory"
    cd "$targetDirectory"/releases/d1/public || { echo >&2 "Failed to cd into:$targetDirectory/releases/d1/public "; exit 1; }
    touch index.php
    echo "<?php phpinfo(); ?>" > index.php
    ln -nfs "$container"/"$parentDirectory"/releases/d1 "$container"/"$parentDirectory"/current

    ls -al "$container"/"$parentDirectory"
    return 0
  fi
  return 1
}

container=$(createSiteContainer)
createLaravelWorkspace "$user" "$container" "$domainName"