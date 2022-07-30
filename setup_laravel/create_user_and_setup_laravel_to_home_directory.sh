#!/bin/bash

type setfacl >/dev/null 2>&1 || { echo >&2 " acl is not installed.  Aborting."; exit 1; }

#domainName='staging.katchup.tech'
#user='esc'

function validateNumericInput () {
  local mode="$1"
  local min="$2"
  local max="$3"

  if ! [[ "$mode" =~ ^[0-9]$ ]] ;
   then
    echo "Input not a number. Exiting...."
    exit 1
  fi

  if [[ $mode -gt $max || $mode -lt $min ]]
    then
      echo "Input out of range. Exiting...."
      exit 1
  fi
}


function createSiteContainer () {
  local user="$1"
  cd /home/"$user" || { echo "User home directory not found at line $LINENO. Exiting...."; exit 1; }
  if [ -d apps/bashTest/example/sites ]
  then
    echo /home/"$user"/"$container"
  else
    if [ ! -d apps ]
    then
      mkdir apps
      setfacl -m u:"$user":rwx apps
      setfacl -m d:u:"$user":rwx apps
      setfacl -m u:www-data:rx apps
      setfacl -m d:u:www-data:rx apps
      setfacl -m m:rwx apps
      setfacl -m d:m:rwx apps
    fi
   cd apps || { echo "apps directory not found at line $LINENO. Exiting...."; exit 1; }
   container=apps/bashTest/example/sites
   mkdir -p "$container"
   echo /home/"$user"/"$container"
  fi
}

function createLaravelWorkspace () {
  local targetUser=$1
  local container=$2
  local parentDirectory=$3
  local targetDirectory=""
  cd "$container" || { echo "$container : Does not exist at line $LINENO. Exiting...."; exit 1; }

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
  targetDirectory="$parentDirectory"/storage
  setfacl -m u:"$targetUser":rwx "$targetDirectory"
  setfacl -m d:u:"$targetUser":rwx "$targetDirectory"
  setfacl -m u:www-data:rwx "$targetDirectory"
  setfacl -m d:u:www-data:rwx "$targetDirectory"
  setfacl -m m:rwx "$targetDirectory"
  setfacl -m d:m:rwx "$targetDirectory"

  # create .env and set appropriate permissions
  cd "$container"/"$parentDirectory" || { echo "$container/$parentDirectory : Does not exist at line $LINENO. Exiting...."; exit 1; }
  touch .env
  setfacl -m u:"$targetUser":rwx .env
  setfacl -m u:www-data:r-- .env

  # Build a new release to test our setup
  targetDirectory="$container"/"$parentDirectory"
  cd "$targetDirectory"/releases/d1/public || { echo "$container/$parentDirectory/releases/d1/public : Does not exist at line $LINENO. Exiting...."; exit 1; }
  touch index.php
  echo "<?php phpinfo(); ?>" > index.php
  ln -nfs "$container"/"$parentDirectory"/releases/d1 "$container"/"$parentDirectory"/current

  ls -al "$targetDirectory"
  return 0
}


function deployApplication () {
  local subMode
  local container
  local domainName
  local user="$1"
  echo "Choose application type"
  echo "1. Laravel"
  echo "2. Vue"
  echo "----------Select (1-2)----------"
  read -n1 -s subMode
  validateNumericInput "$subMode" 1 2
  if [[ $subMode -eq 2 ]]
    then
      echo "<<<<<<<<<<Currently not supporting vue application deployment>>>>>>>>>>"
    fi
  if [[ $subMode -eq 1 ]]
    then
      echo "Deploying Laravel Application:"
      read -p "Enter domain name:" domainName
      container=$(createSiteContainer "$user")
      createLaravelWorkspace "$user" "$container" "$domainName"
      echo "================================"
      echo "Deployment Done"
      echo "================================"
    fi
}

function init () {
  local mode
  local userName
  while :
    do
      echo "1: Create User and deploy application"
      echo "2: User already exist and deploy application"
      echo "3: Cancel Operation"
      echo "----------Select (1-3)----------"
      read -n1 -s mode
      validateNumericInput "$mode" 1 3
      if [[ $mode -eq 1 ]]
        then
          # create User

          # Deploy application
          deployApplication
          continue
        fi

      if [[ $mode -eq 2 ]]
        then
          # Get User name
          read -p "Write User Name (eg: tom):" userName
          if [[ $userName == "" ]]; then echo "Gave invalid user name. Exiting..."; exit 1; fi;

          # Deploy application
          deployApplication "$userName"
          continue
         fi

      exit 0
    done
}

init
