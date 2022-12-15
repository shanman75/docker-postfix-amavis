#!/bin/sh

# Download configuration from local repository

export URLBASE=https://storage.googleapis.com/storage/v1/b
export BUCKET=spinks-config
export VERSION=mailgw-v1


function download_config ()
{
  module=$1
  sourceobject=$2
  destobject=$3

  myurl="$URLBASE/$BUCKET/o/$VERSION%2F$module%2F$sourceobject?alt=media"
  echo "Downloading $url sourceobject=$sourceobject"

  mkdir -p $module
  http_response=$(curl -s -o $module/$destobject -w "%{http_code}" $myurl)

  if [ $http_response != "200" ]; then
      # handle error
    echo "Error with object"
  else
    echo "Server returned object"
    cp -f $module/$destobject /etc/$module/$destobject
  fi
}

download_config "postfix" "transport" "transport"
download_config "postfix" "transport2" "transport2"
download_config "postfix" "aliases" "aliases"
